<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    boolean searched = "POST".equals(request.getMethod());
    String min = searched ? request.getParameter("min") : "3";
    if (min == null || !min.matches("\\d{1,9}")) min = "0";

    try (Connection db = openDb()) {
        ResultSet r = null;
        if (searched) {
            r = prepare(db, """
                    SELECT G.group_id, G.group_name, V.paper_count
                    FROM STUDY_GROUP G, (SELECT group_id, COUNT(*) AS paper_count FROM GROUP_PAPER GROUP BY group_id) V
                    WHERE G.group_id = V.group_id AND G.group_id = ? AND V.paper_count >= ?
                    """, currentGroup(db, session), Integer.parseInt(min)).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>등록 편수별 그룹 | PaperShare</title>
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
            <h1>등록 편수별 그룹<span class="accent">.</span></h1>
            <p class="muted">현재 그룹에 등록된 논문 수가 기준 이상인지 확인하세요.</p>
        </div>
    </div>
    <div class="task-content">
        <section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>검색 조건</h2><p>현재 그룹의 등록 논문 수가 입력한 값 이상이면 결과에 나와요.</p></div>
            </div>
            <form method="post" class="task-form">
                <div class="form-grid">
                    <div class="form-field">
                        <label for="phase2Query7-min">최소 등록 편수</label>
                        <input id="phase2Query7-min" name="min" type="number" min="0" required value="<%= escapeHtml(min) %>">
                    </div>
                </div>
                <div class="form-actions"><button type="submit" class="button button-primary">그룹 검색<span aria-hidden="true">→</span></button></div>
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
        application.log("phase2Query7 실패", e);
    }
%>