<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    boolean searched = "POST".equals(request.getMethod());
    String min = searched ? request.getParameter("min") : "1";
    if (min == null || !min.matches("\\d{1,9}")) min = "0";

    try (Connection db = openDb()) {
        ResultSet r = null;
        if (searched) {
            r = prepare(db, """
                    SELECT G.group_id, G.group_name, GP.group_paper_id, P.paper_id, P.title,
                    COUNT(C.comment_no) AS comment_count, COUNT(DISTINCT C.user_id) AS commenter_count
                    FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P, PAPER_COMMENT C
                    WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
                    AND GP.group_paper_id = C.group_paper_id AND G.group_id = ?
                    GROUP BY G.group_id, G.group_name, GP.group_paper_id, P.paper_id, P.title
                    HAVING COUNT(C.comment_no) >= ? ORDER BY comment_count DESC, GP.group_paper_id
                    """, currentGroup(db, session), Integer.parseInt(min)).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>댓글 통계 | PaperShare</title>
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
            <h1>댓글 통계<span class="accent">.</span></h1>
            <p class="muted">현재 그룹 논문별 댓글 수와 댓글 작성자 수를 확인하세요.</p>
        </div>
    </div>
    <div class="task-content">
        <section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>검색 조건</h2><p>댓글 수가 입력한 값 이상인 논문만 보여 줘요.</p></div>
            </div>
            <form method="post" class="task-form">
                <div class="form-grid">
                    <div class="form-field">
                        <label for="phase2Query9-min">최소 댓글 수</label>
                        <input id="phase2Query9-min" name="min" type="number" min="0" required value="<%= escapeHtml(min) %>">
                    </div>
                </div>
                <div class="form-actions"><button type="submit" class="button button-primary">통계 보기<span aria-hidden="true">→</span></button></div>
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
        application.log("phase2Query9 실패", e);
    }
%>