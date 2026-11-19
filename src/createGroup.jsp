<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%!
    private int querySQL(Connection db, String sql) throws SQLException {
        try (PreparedStatement s = prepare(db, sql); ResultSet r = s.executeQuery()) {
            r.next();
            return r.getInt(1);
        }
    }
%>
<%
    if ("POST".equals(request.getMethod())) {
        try (Connection db = openDb()) {
            db.setAutoCommit(false);
            try {
                int group = querySQL(db, "SELECT NVL(MAX(group_id), 0) + 1 FROM STUDY_GROUP");
                updateSQL(db, "INSERT INTO STUDY_GROUP VALUES (?, ?, SYSTIMESTAMP, ?)",
                        group,
                        request.getParameter("groupName"),
                        request.getParameter("description"));

                updateSQL(db, "INSERT INTO MEMBER_OF VALUES (?, ?, 'LEADER')",
                        session.getAttribute("userId"),
                        group);

                db.commit();
                session.setAttribute("groupId", group);
            } finally {
                db.rollback();
            }
        } catch (Exception ignored) {
        }
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>그룹 생성 | PaperShare</title>
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
    <main class="page-shell task-shell task-shell--form">
        <div class="task-heading">
            <div>
                <p class="eyebrow">USER & GROUP</p>
                <h1>그룹 생성<span class="accent">.</span></h1>
                <p class="muted">새로운 스터디를 만들고 함께 읽는 기록을 시작하세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>새 그룹 만들기</h2><p>그룹의 이름과 소개를 작성하세요</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid">
                <div class="form-field">
                    <label for="createGroup-groupName">그룹명</label>
                    <input placeholder="예: 논문 읽기 스터디" id="createGroup-groupName" name="groupName" required>
                </div>
                <div class="form-field form-field--wide">
                    <label for="createGroup-description">설명</label>
                    <textarea rows="4" placeholder="함께 읽을 주제와 스터디를 소개해 주세요." id="createGroup-description" name="description" required></textarea>
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">그룹 만들기<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
        </div>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
