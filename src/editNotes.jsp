<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    request.setCharacterEncoding("UTF-8");
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");
    String groupPaperParam = request.getParameter("groupPaperId");

    Integer groupPaperId = null;
    String title = null;
    String notes = null;
    String status = null;
    String startedDate = null;
    String completedDate = null;
    String message = null;

    String newNotes = request.getParameter("notes");
    String newStatus = request.getParameter("status");

    String versionParam = request.getParameter("version");
    String version = null;



    try (Connection db = openDb()) {
        if (groupId == null) {
            try (PreparedStatement s = db.prepareStatement(
                    "SELECT group_id FROM MEMBER_OF WHERE user_id = ? ORDER BY group_id")) {
                s.setInt(1, userId);
                try (ResultSet r = s.executeQuery()) {
                    if (r.next()) {
                        groupId = r.getInt(1);
                        session.setAttribute("groupId", groupId);
                    }
                }
            }
        }


        if (groupId == null) {
            message = "먼저 그룹을 생성하거나 가입하세요.";
        } else if (groupPaperParam == null || !groupPaperParam.matches("\\d{1,9}")) {
            message = "논문 리뷰 화면에서 논문을 선택한 뒤 들어오세요.";

        } else {
            groupPaperId = Integer.parseInt(groupPaperParam);

            String checkSql = """
                    SELECT P.title, GP.notes, GP.status,
                           TO_CHAR(GP.started_date, 'YYYY-MM-DD'), TO_CHAR(GP.completed_date, 'YYYY-MM-DD'),
                           TO_CHAR(ORA_HASH(GP.notes)) || ':' || GP.status
                    FROM GROUP_PAPER GP JOIN PAPER P ON P.paper_id = GP.paper_id
                    JOIN MEMBER_OF M ON M.group_id = GP.group_id
                    WHERE GP.group_paper_id = ? AND GP.group_id = ? AND M.user_id = ?
                    """;
            try (PreparedStatement s = db.prepareStatement(checkSql)) {
                s.setInt(1, groupPaperId);
                s.setInt(2, groupId);
                s.setInt(3, userId);

                try (ResultSet r = s.executeQuery()) {
                    if (r.next()) {
                        title = r.getString(1);
                        notes = r.getString(2);
                        status = r.getString(3);
                        startedDate = r.getString(4);
                        completedDate = r.getString(5);
                        version = r.getString(6);
                    }
                }
            }

            if (title == null) {
                response.setStatus(404);
                message = "현재 그룹에서 해당 논문을 찾을 수 없습니다.";
            } else if ("POST".equals(request.getMethod())) {
                if (newNotes == null || newNotes.isBlank()) {
                    message = "그룹 메모를 입력하세요.";
                } else if (!"읽음".equals(newStatus) && !"리뷰중".equals(newStatus) && !"완료".equals(newStatus)) {
                    message = "상태는 읽음, 리뷰중, 완료 중 하나여야 합니다.";
                } else {
                    int changed;
                    try (PreparedStatement s = db.prepareStatement("""
                            UPDATE GROUP_PAPER SET notes = ?, status = ?,
                                started_date = CASE WHEN ? = '읽음' THEN NULL ELSE NVL(started_date, SYSDATE) END,
                                completed_date = CASE WHEN ? = '완료' THEN SYSDATE ELSE NULL END
                            WHERE group_paper_id = ?
                              AND TO_CHAR(ORA_HASH(notes)) || ':' || status = ?
                            """)) {
                        s.setString(1, newNotes);
                        s.setString(2, newStatus);
                        s.setString(3, newStatus);
                        s.setString(4, newStatus);
                        s.setInt(5, groupPaperId);
                        s.setString(6, versionParam);
                        changed = s.executeUpdate();
                    }

                    message = (changed == 1)
                            ? "그룹 메모와 상태를 저장했어요."
                            : "다른 그룹원이 먼저 수정했어요. 아래 최신 내용을 확인한 뒤 다시 저장하세요.";


                    try (PreparedStatement s = db.prepareStatement(checkSql)) {
                        s.setInt(1, groupPaperId);
                        s.setInt(2, groupId);
                        s.setInt(3, userId);
                        try (ResultSet r = s.executeQuery()) {
                            if (r.next()) {
                                notes = r.getString(2);
                                status = r.getString(3);
                                startedDate = r.getString(4);
                                completedDate = r.getString(5);
                                version = r.getString(6);
                            }
                        }
                    }
                }
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("그룹 메모 수정 실패", e);
        message = "그룹 메모를 불러오지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }

    String backHref = (title != null) ? "paperDetail.jsp?groupPaperId=" + groupPaperId : "paperDetail.jsp";

%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>그룹 메모·상태 수정 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
    <style>
        .notes-panel { margin-top: 24px; padding: 24px; }
        .notes-panel h2 { margin: 0 0 16px; font-size: 1.2rem; }
        .notes-panel dl { display: grid; grid-template-columns: 80px 1fr; gap: 8px 16px; margin: 0; }
        .notes-panel dt { color: #777; }
        .notes-panel dd { margin: 0; }
        .notes-form { display: grid; gap: 12px; }
        .notes-form textarea { width: 100%; min-height: 120px; padding: 12px; font: inherit; box-sizing: border-box; }
        .notes-form select { padding: 10px; font: inherit; max-width: 200px; }
    </style>
</head>
<body>
<header class="site-header">
    <div class="header-inner">
        <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
        <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><a class="nav-link" href="<%= escapeHtml(backHref) %>">논문 리뷰</a><span class="nav-link active" aria-current="page">메모·상태 수정</span></nav>
        <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
    </div>
</header>
<main class="page-shell detail-shell">
    <a class="back-link" href="<%= escapeHtml(backHref) %>"><span aria-hidden="true">←</span> 논문 리뷰로</a>
    <div class="detail-heading"><div><p class="eyebrow">NOTES &amp; STATUS</p><h1>메모·상태 수정<span class="accent">.</span></h1><p class="muted"><%= title == null ? "논문을 선택하세요." : escapeHtml(title) %></p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
    <p class="notice" role="status"><%= escapeHtml(message) %></p>
    <% } %>

    <% if (title != null) { %>
    <section class="panel notes-panel">
        <h2>현재 상태</h2>
        <dl>
            <dt>상태</dt><dd><%= escapeHtml(status) %></dd>
            <dt>시작일</dt><dd><%= startedDate == null ? "-" : escapeHtml(startedDate) %></dd>
            <dt>완료일</dt><dd><%= completedDate == null ? "-" : escapeHtml(completedDate) %></dd>
        </dl>
    </section>

    <section class="panel notes-panel">
        <h2>수정하기</h2>
        <form action="editNotes.jsp" method="post" class="notes-form">
            <input type="hidden" name="groupPaperId" value="<%= groupPaperId %>">
            <input type="hidden" name="version" value="<%= escapeHtml(version) %>">
            <label for="notes">그룹 메모</label>
            <textarea id="notes" name="notes" required><%= escapeHtml(notes) %></textarea>
            <label for="status">상태</label>
            <select id="status" name="status" required>
                <option value="읽음" <%= "읽음".equals(status) ? "selected" : "" %>>읽음</option>
                <option value="리뷰중" <%= "리뷰중".equals(status) ? "selected" : "" %>>리뷰중</option>
                <option value="완료" <%= "완료".equals(status) ? "selected" : "" %>>완료</option>
            </select>
            <p class="muted">리뷰중으로 바꾸면 시작일이, 완료로 바꾸면 완료일이 오늘로 기록돼요. 읽음으로 되돌리면 날짜가 지워져요.</p>
            <div><button type="submit" class="button button-primary">저장<span aria-hidden="true">→</span></button></div>
        </form>
    </section>
    <% } %>
</main>
<footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>