<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            r = prepare(db, """
                    SELECT G.group_id, G.group_name, COUNT(P.paper_id) AS done_count, MAX(P.year) AS latest_year
                    FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P
                    WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
                    AND G.group_id = ? AND GP.status = '완료'
                    GROUP BY G.group_id, G.group_name HAVING COUNT(P.paper_id) >= ?
                    """, currentGroup(db, session), request.getParameter("minimum")).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>완료 논문 통계 | PaperShare</title>
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
                <h1>완료 논문 통계<span class="accent">.</span></h1>
                <p class="muted">함께 읽기를 마친 논문의 수와 발행연도를 살펴보세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>통계 조건</h2><p>조회할 최소 완료 편수를 입력하세요</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid">
                <div class="form-field">
                    <label for="phase2Query3-minimum">최소 완료 편수</label>
                    <input id="phase2Query3-minimum" name="minimum" type="number" required value="1">
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">통계 조회<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
<% if ("POST".equals(request.getMethod())) {
       int columns = r.getMetaData().getColumnCount();
%>
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>완료 논문 통계</h2></div></div>
            <div class="table-scroll" role="region" aria-label="완료 논문 통계" tabindex="0">
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
