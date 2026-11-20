<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%!
    private static final String DELETED = "(삭제된 댓글입니다)";

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
                        message = "삭제할 댓글을 선택하세요.";
                    } else {
                        int commentNo = Integer.parseInt(commentParam);


                        boolean mine = false;
                        Integer parentNo = null;
                        try (PreparedStatement s = db.prepareStatement("""
                                SELECT parent_comment_no FROM PAPER_COMMENT
                                WHERE group_paper_id = ? AND comment_no = ? AND user_id = ? AND content <> ?
                                """)) {
                            s.setInt(1, groupPaperId);
                            s.setInt(2, commentNo);
                            s.setInt(3, userId);
                            s.setString(4, DELETED);
                            try (ResultSet r = s.executeQuery()) {
                                if (r.next()) {
                                    mine = true;
                                    int p = r.getInt(1);
                                    parentNo = r.wasNull() ? null : p;
                                }
                            }
                        }

                        if (!mine) {
                            message = "본인이 작성한 댓글만 삭제할 수 있습니다.";
                        } else {

                            int replies = 0;
                            try (PreparedStatement s = db.prepareStatement(
                                    "SELECT COUNT(*) FROM PAPER_COMMENT WHERE group_paper_id = ? AND parent_comment_no = ?")) {
                                s.setInt(1, groupPaperId);
                                s.setInt(2, commentNo);
                                try (ResultSet r = s.executeQuery()) {
                                    if (r.next()) {
                                        replies = r.getInt(1);
                                    }
                                }
                            }

                            if (replies > 0) {

                                try (PreparedStatement s = db.prepareStatement(
                                        "UPDATE PAPER_COMMENT SET content = ? WHERE group_paper_id = ? AND comment_no = ?")) {
                                    s.setString(1, DELETED);
                                    s.setInt(2, groupPaperId);
                                    s.setInt(3, commentNo);
                                    s.executeUpdate();
                                }
                                message = "답글이 있어서 댓글 #" + commentNo + "은(는) '삭제된 댓글입니다'로 표시했어요.";
                            } else {

                                try (PreparedStatement s = db.prepareStatement(
                                        "DELETE FROM PAPER_COMMENT WHERE group_paper_id = ? AND comment_no = ?")) {
                                    s.setInt(1, groupPaperId);
                                    s.setInt(2, commentNo);
                                    s.executeUpdate();
                                }


                                Integer p = parentNo;
                                while (p != null) {
                                    String content = null;
                                    Integer grandParent = null;
                                    int left = 0;
                                    try (PreparedStatement s = db.prepareStatement("""
                                            SELECT C.content, C.parent_comment_no,
                                                   (SELECT COUNT(*) FROM PAPER_COMMENT R
                                                    WHERE R.group_paper_id = C.group_paper_id
                                                      AND R.parent_comment_no = C.comment_no)
                                            FROM PAPER_COMMENT C
                                            WHERE C.group_paper_id = ? AND C.comment_no = ?
                                            """)) {
                                        s.setInt(1, groupPaperId);
                                        s.setInt(2, p);
                                        try (ResultSet r = s.executeQuery()) {
                                            if (r.next()) {
                                                content = r.getString(1);
                                                int g = r.getInt(2);
                                                grandParent = r.wasNull() ? null : g;
                                                left = r.getInt(3);
                                            }
                                        }
                                    }
                                    if (DELETED.equals(content) && left == 0) {
                                        try (PreparedStatement s = db.prepareStatement(
                                                "DELETE FROM PAPER_COMMENT WHERE group_paper_id = ? AND comment_no = ?")) {
                                            s.setInt(1, groupPaperId);
                                            s.setInt(2, p);
                                            s.executeUpdate();
                                        }
                                        p = grandParent;
                                    } else {
                                        break;
                                    }
                                }
                                message = "댓글 #" + commentNo + "을(를) 삭제했어요.";
                            }
                            commentParam = null;
                        }
                    }
                }


                try (PreparedStatement s = db.prepareStatement("""
                        SELECT C.comment_no, C.content,
                               (SELECT COUNT(*) FROM PAPER_COMMENT R
                                WHERE R.group_paper_id = C.group_paper_id
                                  AND R.parent_comment_no = C.comment_no)
                        FROM PAPER_COMMENT C
                        WHERE C.group_paper_id = ? AND C.user_id = ? AND C.content <> ?
                        ORDER BY C.comment_no
                        """)) {
                    s.setInt(1, groupPaperId);
                    s.setInt(2, userId);
                    s.setString(3, DELETED);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            String[] c = { r.getString(1), r.getString(2), r.getString(3) };
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
        application.log("댓글 삭제 실패", e);
        message = "댓글을 삭제하지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>내 댓글 삭제 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .dc-panel { margin-top: 24px; padding: 24px; }
        .dc-panel h2 { margin: 0 0 16px; font-size: 1.2rem; }
        .dc-form { display: grid; gap: 12px; }
        .dc-form label { display: grid; gap: 6px; }
        .dc-form select { padding: 10px; font: inherit; box-sizing: border-box; width: 100%; }
        .dc-preview { padding: 12px 16px; border-left: 3px solid #d9a5a5; background: #fdf6f6; }
        .dc-danger { background: #b5544f; border-color: #b5544f; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">내 댓글 삭제</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">DELETE COMMENT</p><h1>내 댓글 삭제<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %>
        <% if (title != null) { %> <a href="showAnnotations.jsp?groupPaperId=<%= groupPaperId %>">하이라이트·댓글 보기 →</a><% } %>
    </p>
    <% } %>

    <% if (title != null && !myComments.isEmpty()) { %>
    <section class="panel dc-panel">
        <h2>1. 삭제할 댓글 고르기</h2>
        <form action="deleteComment.jsp" method="get" class="dc-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <label>내 댓글
                <select name="commentNo" required onchange="this.form.submit()">
                    <option value="">선택하세요</option>
                    <% for (String[] c : myComments) { %>
                    <option value="<%= escapeHtml(c[0]) %>" <%= c == selected ? "selected" : "" %>>#<%= escapeHtml(c[0]) %> <%= escapeHtml(shorten(c[1])) %><%= "0".equals(c[2]) ? "" : " (답글 " + escapeHtml(c[2]) + "개)" %></option>
                    <% } %>
                </select>
            </label>
        </form>
    </section>

    <% if (selected != null) { %>
    <section class="panel dc-panel">
        <h2>2. 댓글 #<%= escapeHtml(selected[0]) %> 삭제하기</h2>
        <div class="dc-preview"><%= escapeHtml(selected[1]) %></div>
        <form action="deleteComment.jsp" method="post" class="dc-form" style="margin-top: 16px;">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <input type="hidden" name="commentNo" value="<%= escapeHtml(selected[0]) %>">
            <% if ("0".equals(selected[2])) { %>
            <p class="muted">삭제한 댓글은 되돌릴 수 없어요.</p>
            <% } else { %>
            <p class="muted">답글이 <%= escapeHtml(selected[2]) %>개 달려 있어서, 답글은 남고 이 댓글은 '삭제된 댓글입니다'로 표시돼요.</p>
            <% } %>
            <div><button type="submit" class="button button-primary dc-danger">삭제</button></div>
        </form>
    </section>
    <% } %>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>