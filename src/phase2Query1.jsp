<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            String year = request.getParameter("year");
            String title = "%" + request.getParameter("title") + "%";
            String paperId = request.getParameter("paperId");
            String sql = """
                    SELECT paper_id, title, authors, year FROM PAPER
                    WHERE year >= ? AND LOWER(title) LIKE LOWER(?)
                    """;
            PreparedStatement query = paperId == null || paperId.isBlank()
                    ? prepare(db, sql, year, title)
                    : prepare(db, sql + "AND paper_id = ?", year, title, paperId.strip());
            r = query.executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>연도·제목 검색 | PaperShare</title>
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
                <h1>연도·제목 검색<span class="accent">.</span></h1>
                <p class="muted">발행연도와 제목으로 찾고 싶은 논문을 조회하세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>검색 조건</h2><p>논문 ID를 비워 두면 연도와 제목에 맞는 모든 논문을 조회합니다.</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid form-grid--three">
                <div class="form-field">
                    <label for="phase2Query1-year">최소 발행연도</label>
                    <input id="phase2Query1-year" name="year" type="number" required value="2024">
                </div>
                <div class="form-field">
                    <label for="phase2Query1-title">제목 일부</label>
                    <input placeholder="전체를 조회하려면 비워 두세요" id="phase2Query1-title" name="title">
                </div>
                <div class="form-field">
                    <label for="phase2Query1-paperId">논문 ID (선택)</label>
                    <input placeholder="예: 1" id="phase2Query1-paperId" name="paperId" type="number">
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">논문 검색<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
<% if ("POST".equals(request.getMethod())) { %>
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>검색 결과</h2></div></div>
            <div class="table-scroll" role="region" aria-label="검색 결과" tabindex="0">
<table class="data-table">
    <thead>
    <tr><th>PAPER_ID</th><th>TITLE</th><th>AUTHORS</th><th>YEAR</th></tr>
    </thead>
    <tbody>
    <% while (r.next()) { %>
    <tr>
        <td><%= escapeHtml(r.getString(1)) %></td>
        <td><%= escapeHtml(r.getString(2)) %></td>
        <td><%= escapeHtml(r.getString(3)) %></td>
        <td><%= escapeHtml(r.getString(4)) %></td>
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
