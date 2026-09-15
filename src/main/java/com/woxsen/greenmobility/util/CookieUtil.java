package com.woxsen.greenmobility.util;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * Cookie helpers for the two pieces of state that must OUTLIVE the HttpSession:
 *
 *  - remembered login email (so a returning student doesn't retype it)
 *  - recently viewed slots (a browsing trail kept across visits)
 *
 * Contrast with HttpSession, which holds the logged-in Student and dies on
 * logout/timeout. Nothing security-sensitive is ever stored here — no password,
 * no session token — because cookies live on the student's own machine.
 */
public class CookieUtil {

    public static final String REMEMBERED_EMAIL = "rememberedEmail";
    public static final String RECENT_SLOTS = "recentSlots";

    private static final int MAX_RECENT_SLOTS = 4;
    public static final int ONE_MONTH = 60 * 60 * 24 * 30;
    public static final int ONE_WEEK = 60 * 60 * 24 * 7;

    /** Returns the decoded value of a cookie, or null when it isn't set. */
    public static String read(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        for (Cookie c : cookies) {
            if (name.equals(c.getName())) {
                String raw = c.getValue();
                if (raw == null || raw.isEmpty()) {
                    return null;
                }
                return URLDecoder.decode(raw, StandardCharsets.UTF_8);
            }
        }
        return null;
    }

    public static void write(HttpServletRequest request, HttpServletResponse response,
                             String name, String value, int maxAgeSeconds) {
        Cookie cookie = new Cookie(name, URLEncoder.encode(value, StandardCharsets.UTF_8));
        cookie.setMaxAge(maxAgeSeconds);
        cookie.setPath(cookiePath(request));
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    /** Expires a cookie immediately (max-age 0), e.g. when "remember me" is unticked. */
    public static void delete(HttpServletRequest request, HttpServletResponse response, String name) {
        Cookie cookie = new Cookie(name, "");
        cookie.setMaxAge(0);
        cookie.setPath(cookiePath(request));
        response.addCookie(cookie);
    }

    /** Slot ids the student most recently looked at, newest first. */
    public static List<Integer> readRecentSlotIds(HttpServletRequest request) {
        List<Integer> ids = new ArrayList<>();
        String raw = read(request, RECENT_SLOTS);
        if (raw == null) {
            return ids;
        }
        for (String part : raw.split(",")) {
            try {
                ids.add(Integer.parseInt(part.trim()));
            } catch (NumberFormatException ignored) {
                // Cookie values come from the client, so skip anything malformed.
            }
        }
        return ids;
    }

    /**
     * Pushes a slot to the front of the recently-viewed trail, removing any
     * earlier occurrence and capping the list so the cookie stays small.
     */
    public static void pushRecentSlot(HttpServletRequest request, HttpServletResponse response, int slotId) {
        LinkedHashSet<Integer> ordered = new LinkedHashSet<>();
        ordered.add(slotId);
        ordered.addAll(readRecentSlotIds(request));

        StringBuilder sb = new StringBuilder();
        int count = 0;
        for (Integer id : ordered) {
            if (count == MAX_RECENT_SLOTS) {
                break;
            }
            if (count > 0) {
                sb.append(',');
            }
            sb.append(id);
            count++;
        }
        write(request, response, RECENT_SLOTS, sb.toString(), ONE_WEEK);
    }

    /** Context path, or "/" when the app is deployed at the root. */
    private static String cookiePath(HttpServletRequest request) {
        String ctx = request.getContextPath();
        return (ctx == null || ctx.isEmpty()) ? "/" : ctx;
    }
}
