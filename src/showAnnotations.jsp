<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");
    String groupPaperParam = request.getParameter("groupPaperId");

    Integer groupPaperId = null;
    String title = null;
    List<String[]> highlights = new ArrayList<>();
    List<String[]> comments = new ArrayList<>();
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
            } else {
                String highlightSql = """
                        SELECT H.highlight_no, U.name, H.page_no, H.start_position, H.end_position, H.color, H.selected_text, TO_CHAR(H.created_at, 'YYYY-MM-DD HH24:MI')
                        FROM HIGHLIGHT H JOIN USERS U ON U.user_id = H.user_id
                        WHERE H.group_paper_id = ?
                        ORDER BY H.highlight_no
                        """;
                try (PreparedStatement s = db.prepareStatement(highlightSql)) {
                    s.setInt(1, groupPaperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            String[] h = new String[8];
                            for (int i = 0; i < h.length; i++) {
                                h[i] = r.getString(i + 1);
                            }
                            highlights.add(h);
                        }
                    }
                }

                String commentSql = """
                        SELECT C.comment_no, U.name, C.highlight_no, C.parent_comment_no, C.content,
                            TO_CHAR(C.created_at, 'YYYY-MM-DD HH24:MI'),
                            TO_CHAR(C.updated_at, 'YYYY-MM-DD HH24:MI')
                        FROM PAPER_COMMENT C JOIN USERS U ON U.user_id = C.user_id
                        WHERE C.group_paper_id = ?
                        ORDER BY C.comment_no
                        """;
                try(PreparedStatement s = db.prepareStatement(commentSql)){
                    s.setInt(1, groupPaperId);
                    try (ResultSet r = s.executeQuery()) {
                        while (r.next()) {
                            String highlightNo = r.getString(3);
                            String parentNo = r.getString(4);
                            String kind;
                            if (parentNo != null) {
                                kind = "#" + parentNo + "에 답글";
                            } else if (highlightNo != null) {
                                kind = "하이라이트 #" + highlightNo + " 댓글";
                            } else {
                                kind = "일반 메모";
                            }
                            comments.add(new String[] {
                                    r.getString(1), r.getString(2), kind,
                                    r.getString(5), r.getString(6), r.getString(7)
                            });
                        }
                    }
                }
                if (highlights.isEmpty() && comments.isEmpty()){
                    message = "아직 이 논문에 하이라이트와 댓글이 없습니다.";
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e){
        response.setStatus(503);
        application.log("하이라이트와 댓글 조회 실패", e);
        message = "하이라이트와 댓글을 불러오지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";

%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>하이라이트·댓글 조회 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .annotation-panel { margin-top: 24px; padding: 24px; overflow-x: auto; }
        .annotation-panel h2 { margin: 0 0 16px; font-size: 1.2rem; }
        .annotation-table { width: 100%; border-collapse: collapse; font-size: 0.95rem; }
        .annotation-table th, .annotation-table td { padding: 10px 12px; border-bottom: 1px solid rgba(0, 0, 0, 0.08); text-align: left; vertical-align: top; }
        .annotation-table th { font-weight: 600; white-space: nowrap; }
        .annotation-table .num { white-space: nowrap; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">하이라이트·댓글</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">ANNOTATIONS</p><h1>하이라이트·댓글<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %></p>
    <% } %>

    <% if (title != null) { %>
    <section class="panel annotation-panel">
        <h2>하이라이트 <%= highlights.size() %>개</h2>
        <% if (highlights.isEmpty()) { %>
        <p class="muted">아직 하이라이트가 없습니다.</p>
        <% } else { %>
        <table class="annotation-table">
            <thead>
            <tr><th>번호</th><th>작성자</th><th>페이지</th><th>위치</th><th>색상</th><th>선택한 텍스트</th><th>작성일</th></tr>
            </thead>
            <tbody>
            <% for (String[] h : highlights) { %>
            <tr>
                <td class="num">#<%= escapeHtml(h[0]) %></td>
                <td><%= escapeHtml(h[1]) %></td>
                <td class="num"><%= escapeHtml(h[2]) %></td>
                <td class="num"><%= escapeHtml(h[3]) %> ~ <%= escapeHtml(h[4]) %></td>
                <td><%= escapeHtml(h[5]) %></td>
                <td><%= escapeHtml(h[6]) %></td>
                <td class="num"><%= escapeHtml(h[7]) %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </section>

    <section class="panel annotation-panel">
        <h2>댓글 <%= comments.size() %>개</h2>
        <% if (comments.isEmpty()) { %>
        <p class="muted">아직 댓글이 없습니다.</p>
        <% } else { %>
        <table class="annotation-table">
            <thead>
            <tr><th>번호</th><th>작성자</th><th>종류</th><th>내용</th><th>작성일</th><th>수정일</th></tr>
            </thead>
            <tbody>
            <% for (String[] c : comments) { %>
            <tr>
                <td class="num">#<%= escapeHtml(c[0]) %></td>
                <td><%= escapeHtml(c[1]) %></td>
                <td class="num"><%= escapeHtml(c[2]) %></td>
                <td><%= escapeHtml(c[3]) %></td>
                <td class="num"><%= escapeHtml(c[4]) %></td>
                <td class="num"><%= c[5] == null ? "-" : escapeHtml(c[5]) %></td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <% } %>
    </section>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>