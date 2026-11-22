<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    boolean searched = "POST".equals(request.getMethod());
    String tag1 = searched ? request.getParameter("tag1") : "Large Language Models";
    String tag2 = searched ? request.getParameter("tag2") : "Natural Language Processing";

    try (Connection db = openDb()) {
        List<String> tagNames = new ArrayList<>();
        try (PreparedStatement s = prepare(db, "SELECT tag_name FROM TAG ORDER BY tag_name");
             ResultSet t = s.executeQuery()) {
            while (t.next()) tagNames.add(t.getString(1));
        }

        ResultSet r = null;
        if (searched) {
            r = prepare(db, """
                    SELECT P.paper_id, P.title, P.year FROM PAPER P
                    WHERE P.paper_id IN (SELECT GP.paper_id FROM GROUP_PAPER GP WHERE GP.group_id = ?)
                    AND P.paper_id IN (SELECT PT.paper_id FROM PAPER_TAG PT, TAG T
                    WHERE PT.tag_id = T.tag_id AND T.tag_name IN (?, ?))
                    """, currentGroup(db, session), tag1, tag2).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>두 태그 중 하나의 논문 | PaperShare</title>
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
            <h1>두 태그 중 하나의 논문<span class="accent">.</span></h1>
            <p class="muted">현재 그룹 논문 중 두 태그 중 하나라도 붙은 논문을 찾아보세요.</p>
        </div>
    </div>
    <div class="task-content">
        <section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>검색 조건</h2><p>태그 이름을 입력하면 목록에서 고를 수 있어요.</p></div>
            </div>
            <form method="post" class="task-form">
                <div class="form-grid">
                    <div class="form-field">
                        <label for="phase2Query6-tag1">태그 1</label>
                        <input id="phase2Query6-tag1" name="tag1" list="phase2Query6-tags" required value="<%= escapeHtml(tag1) %>">
                    </div>
                    <div class="form-field">
                        <label for="phase2Query6-tag2">태그 2</label>
                        <input id="phase2Query6-tag2" name="tag2" list="phase2Query6-tags" required value="<%= escapeHtml(tag2) %>">
                    </div>
                    <datalist id="phase2Query6-tags">
                        <% for (String tagName : tagNames) { %><option value="<%= escapeHtml(tagName) %>"><% } %>
                    </datalist>
                </div>
                <div class="form-actions"><button type="submit" class="button button-primary">논문 검색<span aria-hidden="true">→</span></button></div>
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
        application.log("phase2Query6 실패", e);
    }
%>