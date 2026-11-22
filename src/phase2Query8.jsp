<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                 SELECT G.group_name, GP.group_paper_id, P.title, H.highlight_no, U.name AS author_name,
                 H.page_no, H.start_position, H.end_position, H.selected_text, H.created_at
                 FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P, HIGHLIGHT H, USERS U
                 WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
                 AND GP.group_paper_id = H.group_paper_id AND H.user_id = U.user_id AND G.group_id = ?
                 ORDER BY P.title, H.page_no, H.start_position, GP.group_paper_id, H.highlight_no
                 """, currentGroup(db, session));
         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>그룹 하이라이트 | PaperShare</title>
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
            <h1>그룹 하이라이트<span class="accent">.</span></h1>
            <p class="muted">현재 그룹의 하이라이트를 논문 제목, 페이지, 위치 순서로 모아 보세요.</p>
        </div>
    </div>
    <div class="task-content">
        <% if (r != null) {
            ResultSetMetaData m = r.getMetaData();
            int n = m.getColumnCount();
            int rows = 0;
        %>
        <section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>그룹 하이라이트</h2></div></div>
            <div class="table-scroll" role="region" aria-label="그룹 하이라이트" tabindex="0">
                <table class="data-table data-table--wide">
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
        application.log("phase2Query8 실패", e);
    }
%>