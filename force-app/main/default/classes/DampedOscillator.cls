public class DampedOscillator {
    
     /** Natural (undamped) angular frequency (rad/s). */
    private final double omega0;

    /** Damping coefficient (s⁻¹). */
    private final double gamma;

    private DampedOscillator() {
        throw new IllegalArgumentException('"No instances."');
    }

    public double[] stepEuler(double[] state, double dt) {
        if (state == null || state.size() != 2) {
            throw new IllegalArgumentException('State must be a non-null array of length 2.');
        }
        if (dt <= 0) {
            throw new IllegalArgumentException('"Time step must be positive."');
        }

        double x = state[0];
        double v = state[1];
        double acceleration = -2.0 * gamma * v - omega0 * omega0 * x;

        double xNext = x + dt * v;
        double vNext = v + dt * acceleration;

        return new double[] {xNext, vNext};
    }
}