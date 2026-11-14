<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    if ("phase2Query".equals(request.getParameter("action"))) {
        response.sendRedirect("phase2Query.jsp");
        return;
    }
%>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PaperShare</title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <header class="site-header">
        <div class="header-inner">
            <a class="brand" href="index.jsp"><span class="brand-mark" aria-hidden="true">p.</span>PaperShare<span class="brand-dot">.</span></a>
            <nav aria-label="주 메뉴">
                <a class="nav-link active" href="index.jsp" aria-current="page">워크스페이스</a>
            </nav>
            <span class="user-badge"><span class="avatar" aria-hidden="true">U</span>사용자 <%= session.getAttribute("userId") %></span>
        </div>
    </header>
    <main class="page-shell">
        <section class="hero">
            <div>
                <p class="eyebrow">A SPACE FOR SHARED IDEAS</p>
                <h1>함께 읽고,<br>더 깊게 나누세요<span class="accent">.</span></h1>
                <p class="hero-description">한 편의 논문에서 시작하는 새로운 생각.<br>스터디의 기록과 대화를 한곳에 모아보세요.</p>
            </div>
            <div class="reading-visual">
                <div class="invitation-top"><span class="overline">SHARED READING NOTES</span></div>
                <div class="paper-illustration" aria-hidden="true"><span class="paper-line short"></span><span class="paper-line"></span><span class="paper-line highlight-line"></span><span class="paper-line"></span><span class="paper-line medium"></span><span class="paper-note">새로운 관점을 더해보세요.</span></div>
                <h2>한 줄의 발견, 함께 나누는 생각.</h2>
                <p>함께 쌓아가는 논문 읽기 기록</p>
            </div>
        </section>

        <div class="section-heading"><div><p class="eyebrow">WORKSPACE</p><h2>우리의 연구 공간</h2></div><span class="section-note">읽는 순간부터 기록이 되도록</span></div>
        <form method="get" class="workspace-grid">
            <div class="panel-stack">
                <section class="panel">
                    <div class="panel-heading"><span class="section-icon" aria-hidden="true">01</span><div><h3>사용자와 그룹</h3><p>함께 읽을 사람들과 만나는 곳</p></div></div>
                    <div class="menu-list">
                        <button class="menu-item" formaction="switchUser.jsp"><span class="menu-number">01</span><span>사용자 전환<small>다른 사용자로 참여하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="showMyGroups.jsp"><span class="menu-number">02</span><span>내 그룹 조회<small>참여 중인 스터디 살펴보기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="switchGroup.jsp"><span class="menu-number">03</span><span>현재 그룹 변경<small>다른 스터디로 이동하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="createGroup.jsp"><span class="menu-number">04</span><span>그룹 생성<small>새로운 스터디 시작하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="joinGroup.jsp"><span class="menu-number">05</span><span>그룹 가입<small>관심 있는 스터디에 함께하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="showGroupMembers.jsp"><span class="menu-number">06</span><span>현재 그룹원 조회<small>함께하는 멤버 확인하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                    </div>
                </section>
                <section class="panel">
                    <div class="panel-heading"><span class="section-icon" aria-hidden="true">03</span><div><h3>검색</h3><p>논문과 그룹의 활동 살펴보기</p></div></div>
                    <div class="menu-list">
                        <button class="menu-item" name="action" value="phase2Query" formaction="index.jsp"><span class="menu-number">17</span><span>Phase2 쿼리 10개<small>실행할 쿼리 선택하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                    </div>
                </section>
            </div>

            <div class="panel-stack">
                <section class="panel">
                    <div class="panel-heading"><span class="section-icon amber" aria-hidden="true">02</span><div><h3>논문 라이브러리</h3><p>차곡차곡 쌓이는 우리의 레퍼런스</p></div></div>
                    <div class="menu-list">
                        <button class="menu-item" formaction="showGroupPapers.jsp"><span class="menu-number">07</span><span>그룹 논문·메모 조회<small>그룹에 모인 논문과 기록 살펴보기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="createPaper.jsp"><span class="menu-number">08</span><span>논문 생성<small>새 논문의 서지정보 등록하기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                        <button class="menu-item" formaction="addPaper.jsp"><span class="menu-number">09</span><span>그룹에 논문 추가<small>함께 읽고 싶은 논문 가져오기</small></span><span class="menu-arrow" aria-hidden="true">↗</span></button>
                    </div>
                </section>
                <section class="panel review-panel">
                    <p class="eyebrow">READ. MARK. DISCUSS.</p>
                    <h3>생각이 머무는 논문 리뷰</h3>
                    <p>중요한 문장에는 하이라이트를,<br>떠오른 생각에는 댓글을 남겨보세요.</p>
                    <div class="tag-list"><span>태그</span><span>메모</span><span>하이라이트</span><span>댓글</span></div>
                    <button class="button button-primary" formaction="paperDetail.jsp">논문 선택하고 리뷰하기 <span aria-hidden="true">→</span></button>
                </section>
            </div>
        </form>
    </main>
    <footer class="site-footer"><span>PaperShare.</span><span>함께 읽는 즐거움, 함께 쌓는 지식.</span></footer>
</body>
</html>
