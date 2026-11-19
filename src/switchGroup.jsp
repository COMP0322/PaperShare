<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        if ("POST".equals(request.getMethod())) {
            session.setAttribute("groupId", Integer.valueOf(request.getParameter("groupId")));
        }

        try (PreparedStatement s = prepare(db, """
                SELECT G.group_id, G.group_name, M.role
                FROM STUDY_GROUP G JOIN MEMBER_OF M ON G.group_id = M.group_id
                WHERE M.user_id = ? ORDER BY G.group_id
                """, session.getAttribute("userId"));
             ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>현재 그룹 변경 | PaperShare</title>
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
                <h1>현재 그룹 변경<span class="accent">.</span></h1>
                <p class="muted">참여 중인 그룹에서 함께 읽을 공간을 선택하세요.</p>
            </div>
        </div>
        <div class="task-content task-content--split">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>그룹 선택</h2><p>목록에서 내 그룹 ID를 확인하세요</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid">
                <div class="form-field">
                    <label for="switchGroup-groupId">내 그룹 ID</label>
                    <input placeholder="예: 1" id="switchGroup-groupId" name="groupId" type="number" required>
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">그룹 변경<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
<section class="panel results-panel">
            <div class="panel-heading"><span class="result-mark" aria-hidden="true"></span><div><h2>내 그룹 목록</h2></div></div>
            <div class="table-scroll" role="region" aria-label="내 그룹 목록" tabindex="0">
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
        }
    } catch (Exception ignored) {
    }
%>
