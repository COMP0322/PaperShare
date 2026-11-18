<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");
    String groupPaperParam = request.getParameter("groupPaperId");

    Integer groupPaperId = null;
    String title = null;
    Integer paperId = null;
    List<String> tags = new ArrayList<>();
    List<String[]> availableTags = new ArrayList<>();
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
        } else if (groupPaperParam == null || !groupPaperParam.matches("\\d{1,9}")) {
            message = "논문 리뷰 화면에서 논문을 선택한 뒤 들어오세요.";

        } else {
            groupPaperId = Integer.parseInt(groupPaperParam);

            String checkSql = """
                    SELECT P.paper_id, P.title
                    FROM GROUP_PAPER GP JOIN PAPER P ON P.paper_id = GP.paper_id
                    JOIN MEMBER_OF M ON M.group_id = GP.group_id
                    WHERE GP.group_paper_id = ? AND GP.group_id = ? AND M.user_id = ?
                    """;
            try (PreparedStatement s = db.prepareStatement(checkSql)) {
                s.setInt(1, groupPaperId);
                s.setInt(2, groupId);
                s.setInt(3, userId);

                try (ResultSet r = s.executeQuery()) {
                    if (r.next()) {
                        paperId = r.getInt(1);
                        title = r.getString(2);
                    }
                }
            }

            if (title == null) {
                response.setStatus(404);
                message = "현재 그룹에서 해당 논문을 찾을 수 없습니다.";
            } else {
                if ("POST".equals(request.getMethod())) {
                    int tagId = Integer.parseInt(request.getParameter("tagId"));

                    try (PreparedStatement s = db.prepareStatement(
                            "INSERT INTO PAPER_TAG (paper_id, tag_id) VALUES (?, ?)")) {
                        s.setInt(1, paperId);
                        s.setInt(2, tagId);
                        s.executeUpdate();
                    }
                    message = "태그를 추가했어요.";
                }
                try (PreparedStatement s = db.prepareStatement("""

                            SELECT T.tag_name
                        FROM PAPER_TAG PT JOIN TAG T ON T.tag_id = PT.tag_id
                        WHERE PT.paper_id = ? ORDER BY T.tag_name
                        """)) {
                    s.setInt(1, paperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            tags.add(r.getString(1));
                        }
                    }
                }


                try (PreparedStatement s = db.prepareStatement("""
                    SELECT T.tag_id, T.tag_name
                    FROM TAG T
                    WHERE NOT EXISTS (SELECT 1 FROM PAPER_TAG PT
                    WHERE PT.tag_id = T.tag_id AND PT.paper_id = ?)
                    ORDER BY T.tag_id
                    """)) {
                        s.setInt(1, paperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            availableTags.add(new String[]{r.getString(1), r.getString(2)});
                        }
                    }
                }
                if (availableTags.isEmpty() && message == null) {
                    message = "추가할 수 있는 태그가 없습니다.";
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("태그 조회 실패", e);
        message = "태그를 불러오지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";

%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>태그 추가 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .tag-panel { margin-top: 24px; padding: 24px; }
        .tag-panel h2 { margin: 0 0 16px; font-size: 1.2rem; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">태그 추가</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">TAGS</p><h1>태그 추가<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %></p>
    <% } %>

    <% if (title != null) { %>
    <section class="panel tag-panel">
        <h2>현재 태그 <%= tags.size() %>개</h2>
        <% if (tags.isEmpty()) { %>
        <p class="muted">아직 붙은 태그가 없습니다.</p>
        <% } else { %>
        <p><%= escapeHtml(String.join(", ", tags)) %></p>
        <% } %>
    </section>

    <% if (!availableTags.isEmpty()) { %>
    <form action="tag.jsp" method="post" class="paper-picker panel" style="margin-top: 24px;">
        <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
        <div class="picker-label"><label for="tagId">추가할 태그</label><span>추가 가능한 태그 <%= availableTags.size() %>개</span></div>
        <div class="picker-controls"><select id="tagId" name="tagId" required>
            <option value="">선택하세요</option>
            <% for (String[] t : availableTags) { %>
            <option value="<%= escapeHtml(t[0]) %>"><%= escapeHtml(t[1]) %></option>
            <% } %>
        </select>
            <button type="submit" class="button button-primary">추가<span aria-hidden="true">→</span></button></div>
    </form>
    <% } %>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>