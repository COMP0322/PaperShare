<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    boolean searched = "POST".equals(request.getMethod());
    String name = searched ? request.getParameter("name") : "";
    if (name == null) name = "";

    try (Connection db = openDb()) {
        ResultSet r = null;
        if (searched) {
            Object group = currentGroup(db, session);
            r = prepare(db, """
                    SELECT U.user_id, U.name FROM USERS U, HIGHLIGHT H, GROUP_PAPER GP
                    WHERE U.user_id = H.user_id AND H.group_paper_id = GP.group_paper_id
                    AND GP.group_id = ? AND U.name LIKE ?
                    INTERSECT
                    SELECT U.user_id, U.name FROM USERS U, PAPER_COMMENT C, GROUP_PAPER GP
                    WHERE U.user_id = C.user_id AND C.group_paper_id = GP.group_paper_id AND GP.group_id = ?
                    """, group, "%" + name.strip() + "%", group).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>하이라이트·댓글 모두 작성한 사용자 | PaperShare</title>
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
            <h1>하이라이트·댓글 모두 작성한 사용자<span class="accent">.</span></h1>
            <p class="muted">현재 그룹에서 하이라이트와 댓글을 모두 남긴 사용자를 찾아보세요.</p>
        </div>
    </div>
    <div class="task-content">
        <section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>검색 조건</h2><p>이름을 비워 두면 해당하는 모든 사용자를 조회합니다.</p></div>
            </div>
            <form method="post" class="task-form">
                <div class="form-grid">
                    <div class="form-field">
                        <label for="phase2Query10-name">이름 일부</label>
                        <input id="phase2Query10-name" name="name" placeholder="전체를 조회하려면 비워 두세요" value="<%= escapeHtml(name) %>">
                    </div>
                </div>
                <div class="form-actions"><button type="submit" class="button button-primary">사용자 검색<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
        <% if (r != null) {
            ResultSetMetaData m = r.getMetaData();
            int n = m.getColumnCount();
            int rows = 0;
        %>
        <section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>검색 결과</h2></div></div>
            <div class="table-scroll" role="region" aria-label="검색 결과" tabindex="0">
                <table class="data-table">
                    <thead>
                    <tr>
                        <% for (int i = 1; i <= n; i++) { %>
                        <th><%= escapeHtml(m.getColumnLabel(i)) %></th>
                        <% } %>
                    </tr>
                    </thead>
                    <tbody>
                    <% while (r.next()) { rows++; %>
                    <tr>
                        <% for (int i = 1; i <= n; i++) { %>
                        <td><%= escapeHtml(r.getString(i)) %></td>
                        <% } %>
                    </tr>
                    <% } %>
                    <% if (rows == 0) { %>
                    <tr><td colspan="<%= n %>">조건에 맞는 결과가 없습니다.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>
        <% } %>
    </div>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
<%
    } catch (Exception e) {
        application.log("phase2Query10 실패", e);
    }
%>