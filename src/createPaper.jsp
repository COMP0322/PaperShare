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
                int paper = querySQL(db, "SELECT NVL(MAX(paper_id), 0) + 1 FROM PAPER");
                updateSQL(db, "INSERT INTO PAPER VALUES (?, ?, ?, ?, ?, ?, ?)", paper,
                        request.getParameter("title"), request.getParameter("authors"),
                        request.getParameter("year"), request.getParameter("doi"),
                        request.getParameter("url"), request.getParameter("abstract"));

                updateSQL(db, """
                        INSERT INTO GROUP_PAPER
                        (group_paper_id, group_id, paper_id, status, added_date, notes)
                        VALUES (?, ?, ?, '읽음', SYSDATE, ?)
                        """, querySQL(db, "SELECT NVL(MAX(group_paper_id), 0) + 1 FROM GROUP_PAPER"),
                        currentGroup(db, session), paper, request.getParameter("notes"));

                db.commit();
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
    <title>논문 생성 | PaperShare</title>
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
                <p class="eyebrow">PAPER LIBRARY</p>
                <h1>논문 생성<span class="accent">.</span></h1>
                <p class="muted">새 논문의 서지정보와 그룹 메모를 함께 등록하세요.</p>
            </div>
        </div>
        <div class="task-content">
<section class="panel form-panel">
            <div class="panel-heading">
                <div><h2>논문 정보 입력</h2><p>논문 정보와 함께 남길 메모를 작성하세요</p></div>
            </div>
            <form method="post" class="task-form">
            <div class="form-grid">
                <div class="form-field form-field--wide">
                    <label for="createPaper-title">제목</label>
                    <input placeholder="논문 제목을 입력하세요" id="createPaper-title" name="title" required>
                </div>
                <div class="form-field form-field--wide">
                    <label for="createPaper-authors">저자</label>
                    <input placeholder="저자 이름을 입력하세요" id="createPaper-authors" name="authors" required>
                </div>
                <div class="form-field">
                    <label for="createPaper-year">발행연도</label>
                    <input id="createPaper-year" name="year" type="number" required min="1" max="9999">
                </div>
                <div class="form-field">
                    <label for="createPaper-doi">DOI</label>
                    <input placeholder="예: 10.1234/example" id="createPaper-doi" name="doi" required>
                </div>
                <div class="form-field form-field--wide">
                    <label for="createPaper-url">URL</label>
                    <input placeholder="논문 원문 주소를 입력하세요" id="createPaper-url" name="url" required>
                </div>
                <div class="form-field form-field--wide">
                    <label for="createPaper-abstract">초록</label>
                    <textarea rows="4" placeholder="논문의 초록을 입력하세요." id="createPaper-abstract" name="abstract" required></textarea>
                </div>
                <div class="form-field form-field--wide">
                    <label for="createPaper-notes">그룹 메모</label>
                    <textarea rows="4" placeholder="그룹과 함께 나눌 메모를 남겨 주세요." id="createPaper-notes" name="notes" required></textarea>
                </div>
            </div>
            <div class="form-actions"><button type="submit" class="button button-primary">논문 등록<span aria-hidden="true">→</span></button></div>
            </form>
        </section>
        </div>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
