<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                SELECT C.group_paper_id, C.comment_no, P.title, U.name, C.content
                FROM PAPER_COMMENT C, GROUP_PAPER GP, PAPER P, USERS U
                WHERE C.group_paper_id = GP.group_paper_id AND GP.paper_id = P.paper_id
                AND C.user_id = U.user_id AND GP.group_id = ?
                AND EXISTS (SELECT 1 FROM PAPER_COMMENT R
                WHERE R.group_paper_id = C.group_paper_id AND R.parent_comment_no = C.comment_no)
                """, currentGroup(db, session));
         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>답글 받은 댓글 | PaperShare</title>
    <link rel="stylesheet" href="assets/style.css?v=20261118-2">
    <link rel="stylesheet" href="assets/workspace.css?v=20261118-2">
</head>
<body class="workspace-page">
    <header class="site-header">
        <div class="header-inner">
            <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
            <nav aria-label="주 메뉴">
                <a class="nav-link" href="index.jsp">워크스페이스</a>
                <a class="nav-link active" href="phase2Query.jsp">검색</a>
            </nav>
        </div>
    </header>
    <main class="page-shell task-shell">
        <div class="task-heading">
            <div>
                <p class="eyebrow">SEARCH</p>
                <h1>답글 받은 댓글<span class="accent">.</span></h1>
                <p class="muted">답글로 이어진 그룹의 논의를 살펴보세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>답글이 이어진 댓글</h2></div></div>
            <div class="table-scroll" role="region" aria-label="답글이 이어진 댓글" tabindex="0">
<table class="data-table">
    <thead>
    <tr>
    <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    </thead>
    <tbody>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
    </tr>
    <% } %>
    </tbody>
</table>
            </div>
        </section>
        </div>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
<%
    } catch (Exception ignored) {
    }
%>
