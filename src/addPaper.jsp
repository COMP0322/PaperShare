<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");

    List<String[]> papers = new ArrayList<>();
    String message = null;

    try (Connection db = openDb()) {
        if (groupId == null) {
            try (PreparedStatement s = db.prepareStatement(
                    "SELECT group_id FROM MEMBER_OF WHERE user_id = ? ORDER BY group_id")) {
                s.setInt(1, userId);
                try (ResultSet r = s.executeQuery()) {
                    if (r.next()) {
                        groupId = r.getInt(1);
                        session.setAttribute("groupId", groupId);
                    }
                }
            }
        }

        if (groupId == null) {
            message = "먼저 그룹을 생성하거나 가입하세요.";
        } else {
            if ("POST".equals(request.getMethod())) {
                request.setCharacterEncoding("UTF-8");
                int paperId = Integer.parseInt(request.getParameter("paperId"));
                String notes = request.getParameter("notes");

                if (notes == null || notes.isBlank()) {
                    message = "그룹 메모를 입력하세요.";
                } else {
                    int newId = 1;
                    try (PreparedStatement s = db.prepareStatement(
                            "SELECT NVL(MAX(group_paper_id), 0) + 1 FROM GROUP_PAPER")) {
                        try (ResultSet r = s.executeQuery()) {
                            if (r.next()) {
                                newId = r.getInt(1);
                            }
                        }
                    }

                    String insertSql = """
                            INSERT INTO GROUP_PAPER
                            (group_paper_id, group_id, paper_id, status, added_date, notes)
                            VALUES (?, ?, ?, '읽음', SYSDATE, ?)
                            """;
                    try (PreparedStatement s = db.prepareStatement(insertSql)) {
                        s.setInt(1, newId);
                        s.setInt(2, groupId);
                        s.setInt(3, paperId);
                        s.setString(4, notes);
                        s.executeUpdate();
                    }
                    message = "논문을 그룹에 추가했어요.";
                }
            }
            String sql = """
                    SELECT P.paper_id, P.title, P.authors, P.year FROM PAPER P
                    WHERE NOT EXISTS (SELECT 1 FROM GROUP_PAPER GP
                                      WHERE GP.paper_id = P.paper_id AND GP.group_id = ?)
                    ORDER BY P.paper_id
                    """;
            try (PreparedStatement s = db.prepareStatement(sql)) {
                s.setInt(1, groupId);
                try (ResultSet r = s.executeQuery()) {
                    while (r.next()) {
                        String[] paper = new String[4];
                        for (int i = 0; i < paper.length; i++) {
                            paper[i] = r.getString(i + 1);
                        }
                        papers.add(paper);

                    }
                }
            }

            if (papers.isEmpty() && message == null) {
                message = "추가할 수 있는 논문이 없습니다.";
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("논문 추가 화면 조회 실패", e);
        message = "논문을 불러오지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>논문 추가 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><span class="nav-link active" aria-current="page">논문 추가</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="index.jsp"><span aria-hidden="true">←</span> 워크스페이스로</a>
    <div class="detail-heading"><div><p class="eyebrow">ADD TO GROUP</p><h1>논문 추가<span class="accent">.</span></h1><p class="muted">그룹에서 함께 읽을 논문을 골라 보세요.</p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %></p>
    <% } %>
    <form action="addPaper.jsp" method="post" class="paper-picker panel">
        <div class="picker-label"><label for="paperId">추가할 논문</label><span>추가 가능한 논문 <%= papers.size() %>편</span></div>
    <div class="picker-controls"><select id="paperId" name="paperId" required>
        <option value="">선택하세요</option>
        <% for (String[] paper : papers) { %>
        <option value="<%= escapeHtml(paper[0]) %>">
            <%= escapeHtml(paper[1]) %>
        </option>
        <% } %>
    </select>
        <input type="text" name="notes" placeholder="그룹 메모" aria-label="그룹 메모" required>
        <button type="submit" class="button button-primary">추가<span aria-hidden="true">→</span></button></div>
    </form>


</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
