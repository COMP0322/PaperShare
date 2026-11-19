<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                SELECT U.name, U.affiliation, M.role FROM USERS U
                JOIN MEMBER_OF M ON U.user_id = M.user_id
                WHERE M.group_id = ? ORDER BY U.user_id
                """, currentGroup(db, session));

         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>현재 그룹원 조회 | PaperShare</title>
    <link rel="stylesheet" href="assets/style.css?v=20261118-2">
    <link rel="stylesheet" href="assets/workspace.css?v=20261118-2">
</head>
<body class="workspace-page">
    <header class="site-header">
        <div class="header-inner">
            <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
            <nav aria-label="주 메뉴">
                <a class="nav-link active" href="index.jsp">워크스페이스</a>
                <a class="nav-link" href="phase2Query.jsp">검색</a>
            </nav>
        </div>
    </header>
    <main class="page-shell task-shell">
        <div class="task-heading">
            <div>
                <p class="eyebrow">USER & GROUP</p>
                <h1>현재 그룹원 조회<span class="accent">.</span></h1>
                <p class="muted">같은 논문을 읽고 생각을 나누는 멤버들을 확인하세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>그룹 멤버</h2></div></div>
            <div class="table-scroll" role="region" aria-label="그룹 멤버" tabindex="0">
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
