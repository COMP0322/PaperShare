<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/common.jspf" %>
<%
    try (Connection db = openDb();
         PreparedStatement s = prepare(db, """
                SELECT C.group_paper_id, C.comment_no, P.title, U.name, C.content
                FROM PAPER_COMMENT C, GROUP_PAPER GP, PAPER P, USERS U
                WHERE C.group_paper_id = GP.group_paper_id AND GP.paper_id = P.paper_id
                AND C.user_id = U.user_id AND GP.group_id = ?
                AND EXISTS (SELECT 1 FROM PAPER_COMMENT R
                WHERE R.group_paper_id = C.group_paper_id AND R.parent_comment_no = C.comment_no)
                """, currentGroup(db, session));
         ResultSet r = s.executeQuery()) {
%>
<!doctype html>
<html lang="ko">
<head><title>17-5 답글 받은 댓글</title></head>
<body>
<table>
    <tr>
    <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <th><%= escapeHtml(r.getMetaData().getColumnLabel(i)) %></th>
    <% } %>
    </tr>
    <% while (r.next()) { %>
    <tr>
        <% for (int i = 1; i <= r.getMetaData().getColumnCount(); i++) { %>
        <td><%= escapeHtml(r.getString(i)) %></td>
        <% } %>
    </tr>
    <% } %>
</table>
</body>
</html>
<%
    } catch (Exception ignored) {
    }
%>
