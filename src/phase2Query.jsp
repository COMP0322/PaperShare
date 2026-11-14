<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Phase2 쿼리 10개 | PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <header class="site-header">
        <div class="header-inner">
            <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
            <nav aria-label="주 메뉴">
                <a class="nav-link" href="index.jsp">워크스페이스</a>
                <a class="nav-link active" href="phase2Query.jsp" aria-current="page">검색</a>
            </nav>
            <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= session.getAttribute("userId") %></span>
        </div>
    </header>
    <main class="page-shell detail-shell">
        <a class="back-link" href="index.jsp">← 워크스페이스로 돌아가기</a>
        <div class="detail-heading">
            <div>
                <p class="eyebrow">SEARCH</p>
                <h1>Phase2 쿼리 10개</h1>
                <p class="muted">조회할 쿼리를 선택하세요.</p>
            </div>
        </div>
        <div class="workspace-grid">
            <section class="panel">
                <div class="panel-heading"><span class="section-icon" aria-hidden="true">01</span><div><h2>논문과 그룹</h2></div></div>
                <div class="menu-list">
                    <a class="menu-item" href="phase2Query1.jsp"><span class="menu-number">01</span><span>연도·제목 검색</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query2.jsp"><span class="menu-number">02</span><span>그룹 리더</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query3.jsp"><span class="menu-number">03</span><span>완료 논문 통계</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query4.jsp"><span class="menu-number">04</span><span>평균보다 최신 논문</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query5.jsp"><span class="menu-number">05</span><span>답글 받은 댓글</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                </div>
            </section>
            <section class="panel">
                <div class="panel-heading"><span class="section-icon amber" aria-hidden="true">02</span><div><h2>태그와 활동</h2></div></div>
                <div class="menu-list">
                    <a class="menu-item" href="phase2Query6.jsp"><span class="menu-number">06</span><span>두 태그 중 하나의 논문</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query7.jsp"><span class="menu-number">07</span><span>등록 편수별 그룹</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query8.jsp"><span class="menu-number">08</span><span>그룹 하이라이트</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query9.jsp"><span class="menu-number">09</span><span>댓글 통계</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                    <a class="menu-item" href="phase2Query10.jsp"><span class="menu-number">10</span><span>하이라이트·댓글 모두 작성한 사용자</span><span class="menu-arrow" aria-hidden="true">↗</span></a>
                </div>
            </section>
        </div>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
