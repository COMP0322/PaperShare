<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb()) {
        ResultSet r = null;
        if ("POST".equals(request.getMethod())) {
            Object group = currentGroup(db, session);
            r = prepare(db, """
                    SELECT P.paper_id, P.title, P.year FROM PAPER P
                    WHERE P.paper_id IN (SELECT GP.paper_id FROM GROUP_PAPER GP WHERE GP.group_id = ?)
                    AND P.year > (SELECT AVG(P2.year) FROM PAPER P2, GROUP_PAPER GP2
                                  WHERE P2.paper_id = GP2.paper_id AND GP2.group_id = ?) + ?
                    """, group, group, request.getParameter("offset")).executeQuery();
        }
%>
<!doctype html>
<html lang="ko">
<head><title>17-4 평균보다 최신 논문</title></head>
<body>
<form method="post">
<table>
    <tr><th>평균 발행연도에 더할 값</th><td><input name="offset" type="number" required value="0"></td></tr>
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
