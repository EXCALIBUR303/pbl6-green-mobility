<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="com.woxsen.greenmobility.model.VehicleSlot" %>
<%@ page import="java.util.List" %>
<%@ page contentType="application/json;charset=UTF-8" %>
<%--
  Polled from availability.jsp (app.js: initLivePolling) so a slot filling up
  -- or a cancellation freeing a seat back up -- shows up for every browser
  looking at it, not just the one that made the booking. All fields here are
  server-computed numbers/booleans, so hand-building the JSON needs no
  escaping library.
--%>
<%
    List<VehicleSlot> slots = new SlotDAO().getUpcomingSlots();
    StringBuilder json = new StringBuilder("[");
    for (int i = 0; i < slots.size(); i++) {
        VehicleSlot s = slots.get(i);
        if (i > 0) json.append(",");
        json.append("{")
            .append("\"slotId\":").append(s.getSlotId()).append(",")
            .append("\"capacity\":").append(s.getCapacity()).append(",")
            .append("\"bookedCount\":").append(s.getBookedCount()).append(",")
            .append("\"remainingCapacity\":").append(s.getRemainingCapacity()).append(",")
            .append("\"fillPercent\":").append(s.getFillPercent()).append(",")
            .append("\"almostFull\":").append(s.isAlmostFull())
            .append("}");
    }
    json.append("]");
    response.setHeader("Cache-Control", "no-store");
    out.print(json);
%>
