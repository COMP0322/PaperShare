<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%!
    private String shorten(String text) {
        if (text == null) return "";
        return text.length() > 40 ? text.substring(0, 40) + "…" : text;
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");
    String groupPaperParam = request.getParameter("groupPaperId");
    String commentParam = request.getParameter("commentNo");
    String newContent = request.getParameter("content");

    Integer groupPaperId = null;
    String title = null;
    String message = null;
    List<String[]> myComments = new ArrayList<>();
    String[] selected = null;

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

            try (PreparedStatement s = db.prepareStatement("""
                    SELECT P.title
                    FROM GROUP_PAPER GP JOIN PAPER P ON P.paper_id = GP.paper_id
                    JOIN MEMBER_OF M ON M.group_id = GP.group_id
                    WHERE GP.group_paper_id = ? AND GP.group_id = ? AND M.user_id = ?
                    """)) {
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
            } else {

                if ("POST".equals(request.getMethod())) {
                    if (commentParam == null || !commentParam.matches("\\d{1,9}")) {
                        message = "수정할 댓글을 선택하세요.";
                    } else if (newContent == null || newContent.isBlank()) {
                        message = "새 내용을 입력하세요.";
                    } else if (newContent.length() > 1000) {
                        message = "내용은 1000자 이하로 입력하세요.";
                    } else {
                        try (PreparedStatement s = db.prepareStatement("""
                                UPDATE PAPER_COMMENT SET content = ?, updated_at = SYSTIMESTAMP
                                WHERE group_paper_id = ? AND comment_no = ? AND user_id = ? AND content <> '(삭제된 댓글입니다)'
                                """)) {
                            s.setString(1, newContent);
                            s.setInt(2, groupPaperId);
                            s.setInt(3, Integer.parseInt(commentParam));
                            s.setInt(4, userId);
                            int changed = s.executeUpdate();
                            message = (changed == 1)
                                    ? "댓글 #" + commentParam + "을(를) 수정했어요."
                                    : "본인이 작성한 댓글만 수정할 수 있습니다.";
                        }
                    }
                }


                try (PreparedStatement s = db.prepareStatement("""
                        SELECT comment_no, content FROM PAPER_COMMENT
                        WHERE group_paper_id = ? AND user_id = ? AND content <> '(삭제된 댓글입니다)' ORDER BY comment_no
                        """)) {
                    s.setInt(1, groupPaperId);
                    s.setInt(2, userId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            String[] c = { r.getString(1), r.getString(2) };
                            myComments.add(c);
                            if (c[0].equals(commentParam)) {
                                selected = c;
                            }
                        }
                    }
                }

                if (myComments.isEmpty() && message == null) {
                    message = "이 논문에 내가 작성한 댓글이 없습니다.";
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("댓글 수정 실패", e);
        message = "댓글을 수정하지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>내 댓글 수정 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .ec-panel { margin-top: 24px; padding: 24px; }
        .ec-panel h2 { margin: 0 0 16px; font-size: 1.2rem; }
        .ec-form { display: grid; gap: 12px; }
        .ec-form label { display: grid; gap: 6px; }
        .ec-form select, .ec-form textarea { padding: 10px; font: inherit; box-sizing: border-box; width: 100%; }
        .ec-form textarea { min-height: 120px; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">내 댓글 수정</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">EDIT COMMENT</p><h1>내 댓글 수정<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %>
        <% if (title != null) { %> <a href="showAnnotations.jsp?groupPaperId=<%= groupPaperId %>">하이라이트·댓글 보기 →</a><% } %>
    </p>
    <% } %>

    <% if (title != null && !myComments.isEmpty()) { %>
    <section class="panel ec-panel">
        <h2>1. 수정할 댓글 고르기</h2>
        <form action="editComment.jsp" method="get" class="ec-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <label>내 댓글
                <select name="commentNo" required onchange="this.form.submit()">
                    <option value="">선택하세요</option>
                    <% for (String[] c : myComments) { %>
                    <option value="<%= escapeHtml(c[0]) %>" <%= c == selected ? "selected" : "" %>>#<%= escapeHtml(c[0]) %> <%= escapeHtml(shorten(c[1])) %></option>
                    <% } %>
                </select>
            </label>
        </form>
    </section>

    <% if (selected != null) { %>
    <section class="panel ec-panel">
        <h2>2. 댓글 #<%= escapeHtml(selected[0]) %> 내용 고치기</h2>
        <form action="editComment.jsp" method="post" class="ec-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <input type="hidden" name="commentNo" value="<%= escapeHtml(selected[0]) %>">
            <label>내용
                <textarea name="content" maxlength="1000" required><%= escapeHtml(selected[1]) %></textarea>
            </label>
            <div><button type="submit" class="button button-primary">저장<span aria-hidden="true">→</span></button></div>
        </form>
    </section>
    <% } %>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>