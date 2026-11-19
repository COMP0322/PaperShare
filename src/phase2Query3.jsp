<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            r = prepare(db, """
                    SELECT G.group_id, G.group_name, COUNT(P.paper_id) AS done_count, MAX(P.year) AS latest_year
                    FROM STUDY_GROUP G, GROUP_PAPER GP, PAPER P
                    WHERE G.group_id = GP.group_id AND GP.paper_id = P.paper_id
                    AND G.group_id = ? AND GP.status = '완료'
                    GROUP BY G.group_id, G.group_name HAVING COUNT(P.paper_id) >= ?
                    """, currentGroup(db, session), request.getParameter("minimum")).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head><title>17-3 완료 논문 통계</title></head>
<body>
<form method="post">
<table>
    <tr><th>최소 완료 편수</th><td><input name="minimum" type="number" required value="1"></td></tr>
</table>
<button type="submit">조회</button>
</form>
<% if ("POST".equals(request.getMethod())) {
       int columns = r.getMetaData().getColumnCount();
%>
<table>
    <tr>
    <% for (int i = 1; i <= columns; i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= columns; i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
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
