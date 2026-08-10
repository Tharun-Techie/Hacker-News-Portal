/**
 * Simple calculator utility with safe operations.
 * Refactors the original hardcoded demo into reusable methods.
 */
public with sharing class secountProgram {
    /**
     * Demo method to showcase usage (kept similar to original hello()).
     */
    public static void hello() {
        Integer a = 10;
        Integer b = 20;

        System.debug(LoggingLevel.DEBUG, 'Add: ' + add(a, b));
        System.debug(LoggingLevel.DEBUG, 'Subtract: ' + subtract(a, b));
        System.debug(LoggingLevel.DEBUG, 'Multiply: ' + multiply(a, b));
        System.debug(LoggingLevel.DEBUG, 'Divide (b/a): ' + divide(b, a));
    }

    // Arithmetic helpers

    public static Integer add(Integer a, Integer b) {
        return (a == null ? 0 : a) + (b == null ? 0 : b);
    }

    public static Integer subtract(Integer a, Integer b) {
        return (a == null ? 0 : a) - (b == null ? 0 : b);
    }

    public static Integer multiply(Integer a, Integer b) {
        return (a == null ? 0 : a) * (b == null ? 0 : b);
    }

    public static Integer divide(Integer a, Integer b) {
        if (b == null || b == 0) {
            // Throwing a meaningful exception provides clear feedback to callers
            throw new IllegalArgumentException('Divider (b) cannot be null or zero.');
        }
        return (a == null ? 0 : a) / b;
    }
}