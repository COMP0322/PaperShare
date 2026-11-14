<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    int userId = (Integer) session.getAttribute("userId");
    Integer groupId = (Integer) session.getAttribute("groupId");

    List<String[]> papers = new ArrayList<>();
    String message = null;
    String[] selectedPaper = null;
    String groupPaperId = request.getParameter("groupPaperId");

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
        } else {
            String sql = """
                    SELECT GP.group_paper_id, P.title, P.authors, P.year, P.DOI,
                           P.url, P.abstract, GP.status, GP.notes
                    FROM GROUP_PAPER GP JOIN PAPER P ON P.paper_id = GP.paper_id
                    JOIN MEMBER_OF M ON M.group_id = GP.group_id
                    WHERE GP.group_id = ? AND M.user_id = ?
                    ORDER BY GP.group_paper_id
                    """;
            try (PreparedStatement s = db.prepareStatement(sql)) {
                s.setInt(1, groupId);
                s.setInt(2, userId);
                try (ResultSet r = s.executeQuery()) {
                    while (r.next()) {
                        String[] paper = new String[9];
                        for (int i = 0; i < paper.length; i++) {
                            paper[i] = r.getString(i + 1);
                        }
                        papers.add(paper);
                        if (paper[0].equals(groupPaperId)) {
                            selectedPaper = paper;
                        }
                    }
                }
            }

            if (groupPaperId != null && selectedPaper == null) {
                response.setStatus(404);
                message = "현재 그룹에서 해당 논문을 찾을 수 없습니다.";
            } else if (papers.isEmpty()) {
                message = "현재 그룹에 등록된 논문이 없습니다.";
            }
        }
    } catch (SQLException | ClassNotFoundException e) {
        response.setStatus(503);
        application.log("논문 상세 조회 실패", e);
        message = "논문을 불러오지 못했습니다. Tomcat 실행 로그와 DB 연결 설정을 확인하세요.";
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>논문 상세 - PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <header class="site-header">
        <div class="header-inner">
            <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
            <nav aria-label="주 메뉴"><a class="nav-link" href="index.jsp">워크스페이스</a><span class="nav-link active" aria-current="page">논문 리뷰</span></nav>
            <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= userId %></span>
        </div>
    </header>
    <main class="page-shell detail-shell">
    <a class="back-link" href="index.jsp"><span aria-hidden="true">←</span> 워크스페이스로</a>
    <div class="detail-heading"><div><p class="eyebrow">THE READING ROOM</p><h1>논문 리뷰<span class="accent">.</span></h1><p class="muted">한 번 선택한 논문에서 모든 이야기를 이어가세요.</p></div><span class="group-badge">현재 그룹 <strong><%= groupId == null ? "없음" : "#" + groupId %></strong></span></div>
    <% if (message != null) { %>
        <p class="notice" role="status"><%= escapeHtml(message) %></p>
    <% } %>
    <% if (!papers.isEmpty()) { %>
        <form action="paperDetail.jsp" method="get" class="paper-picker panel">
            <div class="picker-label"><label for="groupPaperId">어떤 논문을 읽을까요?</label><span>현재 그룹의 논문 <%= papers.size() %>편</span></div>
            <div class="picker-controls"><select id="groupPaperId" name="groupPaperId" required>
                <option value="">선택하세요</option>
                <% for (String[] paper : papers) { %>
                    <option value="<%= escapeHtml(paper[0]) %>" <%= paper == selectedPaper ? "selected" : "" %>>
                        <%= escapeHtml(paper[1]) %>
                    </option>
                <% } %>
            </select>
            <button type="submit" class="button button-primary">논문 열기 <span aria-hidden="true">→</span></button></div>
        </form>
    <% } %>

    <% if (selectedPaper != null) { %>
        <div class="reading-layout">
        <article class="panel paper-document">
            <div class="document-top"><span class="eyebrow">PAPER / <%= escapeHtml(selectedPaper[0]) %></span><span class="status-badge"><%= escapeHtml(selectedPaper[7]) %></span></div>
            <h2><%= escapeHtml(selectedPaper[1]) %></h2>
            <p class="paper-authors"><%= escapeHtml(selectedPaper[2]) %> <span>· <%= escapeHtml(selectedPaper[3]) %></span></p>
            <dl class="paper-metadata">
                <dt>DOI</dt><dd><%= escapeHtml(selectedPaper[4]) %></dd>
                <dt>URL</dt><dd><%= escapeHtml(selectedPaper[5]) %></dd>
            </dl>
            <section class="abstract-section"><h3>Abstract <span>초록</span></h3><p><%= escapeHtml(selectedPaper[6]) %></p></section>
            <section class="notes-section"><h3>그룹 메모</h3><p><%= escapeHtml(selectedPaper[8]) %></p></section>
        </article>
        <aside class="panel action-panel" aria-label="선택한 논문의 기능">
            <p class="eyebrow">MAKE IT YOURS</p><h2>읽고, 기록하고, 나누기</h2><p class="muted">이 논문에서 이어갈 활동을 선택하세요.</p>
        <form method="get" class="review-actions">
            <input type="hidden" name="groupPaperId" value="<%= escapeHtml(selectedPaper[0]) %>">
            <h3 class="action-label">정리하기</h3>
            <button class="action-button" formaction="tag.jsp"><span class="menu-number">10</span>논문 태그 추가<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <button class="action-button" formaction="editNotes.jsp"><span class="menu-number">11</span>그룹 메모·상태 수정<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <h3 class="action-label">함께 읽기</h3>
            <button class="action-button" formaction="highlight.jsp"><span class="menu-number">12</span>하이라이트 생성<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <button class="action-button" formaction="showAnnotations.jsp"><span class="menu-number">13</span>하이라이트·댓글 조회<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <button class="action-button" formaction="comment.jsp"><span class="menu-number">14</span>댓글·답글 생성<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <h3 class="action-label">내 댓글 관리</h3>
            <button class="action-button" formaction="editComment.jsp"><span class="menu-number">15</span>내 댓글 수정<span class="menu-arrow" aria-hidden="true">↗</span></button>
            <button class="action-button danger" formaction="deleteComment.jsp"><span class="menu-number">16</span>내 댓글 삭제<span class="menu-arrow" aria-hidden="true">↗</span></button>
        </form>
        </aside>
        </div>
    <% } else { %>
        <section class="panel empty-state"><span class="empty-mark" aria-hidden="true">p.</span><p class="eyebrow">ROOM FOR YOUR NEXT IDEA</p><h2>함께 읽을 논문을 펼쳐보세요.</h2><p>논문을 선택하면 서지정보와 그룹 메모를 확인하고,<br>하이라이트와 댓글로 생각을 나눌 수 있어요.</p></section>
    <% } %>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
