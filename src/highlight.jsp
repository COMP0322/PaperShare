<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");
    String groupPaperParam = request.getParameter("groupPaperId");

    Integer groupPaperId = null;
    String title = null;
    String message = null;
    Integer createdNo = null;

    String pageParam = request.getParameter("pageNo");
    String startParam = request.getParameter("startPosition");
    String endParam = request.getParameter("endPosition");
    String color = request.getParameter("color");
    String selectedText = request.getParameter("selectedText");
    String[] colors = { "yellow", "green", "blue", "pink", "orange" };

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
                    SELECT P.title
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
                        title = r.getString(1);
                    }
                }
            }

            if (title == null) {
                response.setStatus(404);
                message = "현재 그룹에서 해당 논문을 찾을 수 없습니다.";
            } else if ("POST".equals(request.getMethod())) {
                // 입력 검사 (Phase 3와 같은 규칙)
                boolean numbersOk = pageParam != null && pageParam.matches("\\d{1,9}")
                        && startParam != null && startParam.matches("\\d{1,9}")
                        && endParam != null && endParam.matches("\\d{1,9}");
                boolean colorOk = color != null && java.util.Arrays.asList(colors).contains(color);

                if (!numbersOk) {
                    message = "페이지와 위치는 숫자로 입력하세요.";
                } else if (!colorOk) {
                    message = "색상을 선택하세요.";
                } else if (selectedText == null || selectedText.isBlank()) {
                    message = "선택한 텍스트를 입력하세요.";
                } else if (selectedText.length() > 1000) {
                    message = "선택한 텍스트는 1000자 이하로 입력하세요.";
                } else {
                    int pageNo = Integer.parseInt(pageParam);
                    int start = Integer.parseInt(startParam);
                    int end = Integer.parseInt(endParam);

                    if (pageNo < 1 || start < 0 || end <= start) {
                        message = "페이지는 1 이상, 시작 위치는 0 이상, 끝 위치는 시작 위치보다 커야 합니다.";
                    } else {
                        int no = 1;
                        db.setAutoCommit(false);
                        try {
                            try (PreparedStatement s = db.prepareStatement(
                                    "SELECT group_paper_id FROM GROUP_PAPER WHERE group_paper_id = ? FOR UPDATE")) {
                                s.setInt(1, groupPaperId);
                                s.executeQuery();
                            }


                            try (PreparedStatement s = db.prepareStatement(
                                    "SELECT NVL(MAX(highlight_no), 0) + 1 FROM HIGHLIGHT WHERE group_paper_id = ?")) {
                                s.setInt(1, groupPaperId);
                                try (ResultSet r = s.executeQuery()) {
                                    if (r.next()) {
                                        no = r.getInt(1);
                                    }
                                }
                            }

                            try (PreparedStatement s = db.prepareStatement("""
                                    INSERT INTO HIGHLIGHT
                                    (group_paper_id, highlight_no, user_id, page_no, start_position,
                                     end_position, color, selected_text, created_at)
                                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, SYSTIMESTAMP)
                                    """)) {
                                s.setInt(1, groupPaperId);
                                s.setInt(2, no);
                                s.setInt(3, userId);
                                s.setInt(4, pageNo);
                                s.setInt(5, start);
                                s.setInt(6, end);
                                s.setString(7, color);
                                s.setString(8, selectedText);
                                s.executeUpdate();
                            }

                            db.commit();
                        } catch (SQLException e) {
                            db.rollback();
                            throw e;
                        } finally {
                            db.setAutoCommit(true);
                        }

                        createdNo = no;
                        message = "하이라이트 #" + no + "을(를) 만들었어요.";
                        pageParam = startParam = endParam = selectedText = null;
                        color = null;
                    }
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("하이라이트 생성 실패", e);
        message = "하이라이트를 저장하지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>하이라이트 생성 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .hl-panel { margin-top: 24px; padding: 24px; }
        .hl-form { display: grid; gap: 12px; }
        .hl-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
        .hl-form label { display: grid; gap: 6px; }
        .hl-form input, .hl-form select, .hl-form textarea { padding: 10px; font: inherit; box-sizing: border-box; width: 100%; }
        .hl-form textarea { min-height: 100px; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">하이라이트 생성</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">HIGHLIGHT</p><h1>하이라이트 생성<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %>
        <% if (createdNo != null) { %> <a href="showAnnotations.jsp?groupPaperId=<%= groupPaperId %>">하이라이트·댓글 보기 →</a><% } %>
    </p>
    <% } %>

    <% if (title != null) { %>
    <section class="panel hl-panel">
        <form action="highlight.jsp" method="post" class="hl-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <div class="hl-row">
                <label>페이지 (1 이상)
                    <input type="number" name="pageNo" min="1" required value="<%= escapeHtml(pageParam) %>">
                </label>
                <label>시작 위치 (0 이상)
                    <input type="number" name="startPosition" min="0" required value="<%= escapeHtml(startParam) %>">
                </label>
                <label>끝 위치 (시작보다 크게)
                    <input type="number" name="endPosition" min="1" required value="<%= escapeHtml(endParam) %>">
                </label>
                <label>색상
                    <select name="color" required>
                        <option value="">선택하세요</option>
                        <% for (String c : colors) { %>
                        <option value="<%= c %>" <%= c.equals(color) ? "selected" : "" %>><%= c %></option>
                        <% } %>
                    </select>
                </label>
            </div>
            <label>선택한 텍스트
                <textarea name="selectedText" maxlength="1000" required><%= escapeHtml(selectedText) %></textarea>
            </label>
            <div><button type="submit" class="button button-primary">하이라이트 만들기<span aria-hidden="true">→</span></button></div>
        </form>
    </section>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>