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
    List<String[]> highlights = new ArrayList<>();
    List<String[]> comments = new ArrayList<>();


    String highlightParam = request.getParameter("highlightNo");
    String parentParam = request.getParameter("parentNo");
    String content = request.getParameter("content");

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
                    Integer highlightNo = null;
                    Integer parentNo = null;
                    boolean ok = true;

                    if (content == null || content.isBlank()) {
                        message = "내용을 입력하세요.";
                        ok = false;
                    } else if (content.length() > 1000) {
                        message = "내용은 1000자 이하로 입력하세요.";
                        ok = false;
                    } else if (highlightParam != null && !highlightParam.isEmpty() && !highlightParam.matches("\\d{1,9}")) {
                        message = "하이라이트 번호가 올바르지 않습니다.";
                        ok = false;
                    } else if (parentParam != null && !parentParam.isEmpty() && !parentParam.matches("\\d{1,9}")) {
                        message = "부모 댓글 번호가 올바르지 않습니다.";
                        ok = false;
                    }

                    if (ok) {
                        if (highlightParam != null && !highlightParam.isEmpty()) highlightNo = Integer.parseInt(highlightParam);
                        if (parentParam != null && !parentParam.isEmpty()) parentNo = Integer.parseInt(parentParam);

                        int no = 1;
                        db.setAutoCommit(false);
                        try {

                            try (PreparedStatement s = db.prepareStatement(
                                    "SELECT group_paper_id FROM GROUP_PAPER WHERE group_paper_id = ? FOR UPDATE")) {
                                s.setInt(1, groupPaperId);
                                s.executeQuery();
                            }


                            if (highlightNo != null) {
                                try (PreparedStatement s = db.prepareStatement(
                                        "SELECT 1 FROM HIGHLIGHT WHERE group_paper_id = ? AND highlight_no = ?")) {
                                    s.setInt(1, groupPaperId);
                                    s.setInt(2, highlightNo);
                                    try (ResultSet r = s.executeQuery()) {
                                        if (!r.next()) {
                                            message = "이 논문에 없는 하이라이트입니다.";
                                            ok = false;
                                        }
                                    }
                                }
                            }
                            if (ok && parentNo != null) {
                                try (PreparedStatement s = db.prepareStatement(
                                        "SELECT 1 FROM PAPER_COMMENT WHERE group_paper_id = ? AND comment_no = ?")) {
                                    s.setInt(1, groupPaperId);
                                    s.setInt(2, parentNo);
                                    try (ResultSet r = s.executeQuery()) {
                                        if (!r.next()) {
                                            message = "이 논문에 없는 댓글에는 답글을 달 수 없습니다.";
                                            ok = false;
                                        }
                                    }
                                }
                            }

                            if (ok) {

                                try (PreparedStatement s = db.prepareStatement(
                                        "SELECT NVL(MAX(comment_no), 0) + 1 FROM PAPER_COMMENT WHERE group_paper_id = ?")) {
                                    s.setInt(1, groupPaperId);
                                    try (ResultSet r = s.executeQuery()) {
                                        if (r.next()) {
                                            no = r.getInt(1);
                                        }
                                    }
                                }

                                try (PreparedStatement s = db.prepareStatement("""
                                        INSERT INTO PAPER_COMMENT
                                        (group_paper_id, comment_no, user_id, highlight_no, parent_comment_no, content, created_at)
                                        VALUES (?, ?, ?, ?, ?, ?, SYSTIMESTAMP)
                                        """)) {
                                    s.setInt(1, groupPaperId);
                                    s.setInt(2, no);
                                    s.setInt(3, userId);
                                    if (highlightNo == null) s.setNull(4, Types.INTEGER); else s.setInt(4, highlightNo);
                                    if (parentNo == null) s.setNull(5, Types.INTEGER); else s.setInt(5, parentNo);
                                    s.setString(6, content);
                                    s.executeUpdate();
                                }
                                db.commit();
                            } else {
                                db.rollback();
                            }
                        } catch (SQLException e) {
                            db.rollback();
                            throw e;
                        } finally {
                            db.setAutoCommit(true);
                        }

                        if (ok) {
                            createdNo = no;
                            message = "댓글 #" + no + "을(를) 작성했어요.";
                            highlightParam = parentParam = content = null;
                        }
                    }
                }

                try (PreparedStatement s = db.prepareStatement(
                        "SELECT highlight_no, selected_text FROM HIGHLIGHT WHERE group_paper_id = ? ORDER BY highlight_no")) {
                    s.setInt(1, groupPaperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            highlights.add(new String[] { r.getString(1), r.getString(2) });
                        }
                    }
                }
                try (PreparedStatement s = db.prepareStatement("""
                        SELECT C.comment_no, U.name, C.content
                        FROM PAPER_COMMENT C JOIN USERS U ON U.user_id = C.user_id
                        WHERE C.group_paper_id = ? ORDER BY C.comment_no
                        """)) {
                    s.setInt(1, groupPaperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            comments.add(new String[] { r.getString(1), r.getString(2), r.getString(3) });
                        }
                    }
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("댓글 작성 실패", e);
        message = "댓글을 저장하지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";
%>
<%!
    private String shorten(String text) {
        if (text == null) return "";
        return text.length() > 40 ? text.substring(0, 40) + "…" : text;
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>댓글·답글 생성 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .cm-panel { margin-top: 24px; padding: 24px; }
        .cm-form { display: grid; gap: 12px; }
        .cm-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .cm-form label { display: grid; gap: 6px; }
        .cm-form select, .cm-form textarea { padding: 10px; font: inherit; box-sizing: border-box; width: 100%; }
        .cm-form textarea { min-height: 120px; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">댓글·답글 생성</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">COMMENT</p><h1>댓글·답글 생성<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %>
        <% if (createdNo != null) { %> <a href="showAnnotations.jsp?groupPaperId=<%= groupPaperId %>">하이라이트·댓글 보기 →</a><% } %>
    </p>
    <% } %>

    <% if (title != null) { %>
    <section class="panel cm-panel">
        <form action="comment.jsp" method="post" class="cm-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <div class="cm-row">
                <label>하이라이트에 달기 (선택)
                    <select name="highlightNo">
                        <option value="">없음 — 일반 메모</option>
                        <% for (String[] h : highlights) { %>
                        <option value="<%= escapeHtml(h[0]) %>" <%= h[0].equals(highlightParam) ? "selected" : "" %>>#<%= escapeHtml(h[0]) %> <%= escapeHtml(shorten(h[1])) %></option>
                        <% } %>
                    </select>
                </label>
                <label>답글 달기 (선택)
                    <select name="parentNo">
                        <option value="">없음 — 새 메모</option>
                        <% for (String[] c : comments) { %>
                        <option value="<%= escapeHtml(c[0]) %>" <%= c[0].equals(parentParam) ? "selected" : "" %>>#<%= escapeHtml(c[0]) %> <%= escapeHtml(c[1]) %>: <%= escapeHtml(shorten(c[2])) %></option>
                        <% } %>
                    </select>
                </label>
            </div>
            <label>내용
                <textarea name="content" maxlength="1000" required><%= escapeHtml(content) %></textarea>
            </label>
            <div><button type="submit" class="button button-primary">작성<span aria-hidden="true">→</span></button></div>
        </form>
    </section>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>