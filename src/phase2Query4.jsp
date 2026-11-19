<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            Object group = currentGroup(db, session);
            r = prepare(db, """
                    SELECT P.paper_id, P.title, P.year FROM PAPER P
                    WHERE P.paper_id IN (SELECT GP.paper_id FROM GROUP_PAPER GP WHERE GP.group_id = ?)
                    AND P.year > (SELECT AVG(P2.year) FROM PAPER P2, GROUP_PAPER GP2
                                  WHERE P2.paper_id = GP2.paper_id AND GP2.group_id = ?) + ?
                    """, group, group, request.getParameter("offset")).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>평균보다 최신 논문 | PaperShare</title>
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
                <h1>평균보다 최신 논문<span class="accent">.</span></h1>
                <p class="muted">그룹 논문의 평균 발행연도를 기준으로 최신 논문을 찾아보세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>발행연도 기준</h2><p>평균 발행연도에 더할 값을 입력하세요</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid">
                <div class="form-field">
                    <label for="phase2Query4-offset">평균 발행연도에 더할 값</label>
                    <input id="phase2Query4-offset" name="offset" type="number" required value="0">
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">논문 조회<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
<% if ("POST".equals(request.getMethod())) {
       int columns = r.getMetaData().getColumnCount();
%>
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>조회 결과</h2></div></div>
            <div class="table-scroll" role="region" aria-label="조회 결과" tabindex="0">
<table class="data-table">
    <thead>
    <tr>
    <% for (int i = 1; i <= columns; i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    </thead>
    <tbody>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= columns; i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
    </tr>
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
    } catch (Exception ignored) {
    }
%>
