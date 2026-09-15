<%@ include file="/WEB-INF/jspf/adminGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="java.time.LocalDateTime" %>
<%
    try {
        String vehicleType = request.getParameter("vehicleType");
        String origin = request.getParameter("origin").trim();
        String destination = request.getParameter("destination").trim();
        String route = origin + " -> " + destination;

        // datetime-local posts "yyyy-MM-ddTHH:mm", which LocalDateTime.parse
        // reads directly (ISO_LOCAL_DATE_TIME allows the seconds field to be
        // omitted).
        Timestamp slotTime = Timestamp.valueOf(LocalDateTime.parse(request.getParameter("slotTime")));

        BigDecimal distanceKm = new BigDecimal(request.getParameter("distanceKm"));
        int capacity = Integer.parseInt(request.getParameter("capacity"));

        new SlotDAO().createSlot(vehicleType, route, slotTime, distanceKm, capacity);

        response.sendRedirect(request.getContextPath() +
                "/adminSlots.jsp?status=success&msg=Slot opened: " + route);
    } catch (Exception e) {
        response.sendRedirect(request.getContextPath() +
                "/adminSlots.jsp?status=error&msg=Could not open that slot: " + e.getMessage());
    }
%>
