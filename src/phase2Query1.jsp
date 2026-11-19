<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            r = prepare(db, """
                    SELECT paper_id, title, authors, year FROM PAPER
                    WHERE year >= ? AND LOWER(title) LIKE LOWER(?) AND paper_id IN (?)
                    """, request.getParameter("year"), "%" + request.getParameter("title") + "%",
                    request.getParameter("paperId")).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head><title>17-1 연도·제목 검색</title></head>
<body>
<form method="post">
<table>
    <tr><th>최소 발행연도</th><td><input name="year" type="number" required value="2024"></td></tr>
    <tr><th>제목 일부 (전체는 빈칸)</th><td><input name="title"></td></tr>
    <tr><th>논문 ID</th><td><input name="paperId" type="number" required></td></tr>
</table>
<button type="submit">조회</button>
</form>
<% if ("POST".equals(request.getMethod())) { %>
<table>
    <tr><th>PAPER_ID</th><th>TITLE</th><th>AUTHORS</th><th>YEAR</th></tr>
    <% while (r.next()) { %>
    <tr>
        <td><%= escapeHtml(r.getString(1)) %></td>
        <td><%= escapeHtml(r.getString(2)) %></td>
        <td><%= escapeHtml(r.getString(3)) %></td>
        <td><%= escapeHtml(r.getString(4)) %></td>
    </tr>
    <% } %>
</table>
<% } %>
</body>
</html>
<%
    } catch (Exception ignored) {
    }
%>
