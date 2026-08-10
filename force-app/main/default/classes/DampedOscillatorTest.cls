@IsTest
private class DampedOscillatorTest {

    @IsTest
    static void testStepEulerSuccess() {
        Double[] initialState = new List<Double>{1.0, 0.0};
        Double dt = 0.1; // Variable explicitly declared as Double

        Map<String, Object> fieldMap = new Map<String, Object>{
            'omega0' => 2.0,
            'gamma' => 0.5
        };
        DampedOscillator oscillator = (DampedOscillator) JSON.deserialize(
            JSON.serialize(fieldMap), 
            DampedOscillator.class
        );

        Test.startTest();
        Double[] nextState = oscillator.stepEuler(initialState, dt); // Compiles successfully
        Test.stopTest();

        Assert.areNotEqual(null, nextState, 'Result state should not be null');
        Assert.areEqual(2, nextState.size(), 'Result state array length must be 2');
        Assert.areEqual(1.0, nextState[0], 'Incorrect next position calculation');
        Assert.areEqual(-0.4, nextState[1], 'Incorrect next velocity calculation');
    }

    @IsTest
    static void testStepEulerNullStateThrowsException() {
        DampedOscillator oscillator = (DampedOscillator) JSON.deserialize(
            JSON.serialize(new Map<String, Object>{'omega0' => 1.0, 'gamma' => 1.0}), 
            DampedOscillator.class
        );

        try {
            Test.startTest();
            // Explicitly cast to Double to match method signature
            oscillator.stepEuler(null, (Double)0.1); 
            Test.stopTest();
            Assert.fail('Expected IllegalArgumentException for null state');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('State must be a non-null array of length 2.', e.getMessage());
        }
    }

    @IsTest
    static void testStepEulerInvalidStateSizeThrowsException() {
        DampedOscillator oscillator = (DampedOscillator) JSON.deserialize(
            JSON.serialize(new Map<String, Object>{'omega0' => 1.0, 'gamma' => 1.0}), 
            DampedOscillator.class
        );
        Double[] invalidState = new List<Double>{1.0};

        try {
            Test.startTest();
            oscillator.stepEuler(invalidState, (Double)0.1);
            Test.stopTest();
            Assert.fail('Expected IllegalArgumentException for invalid state size');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('State must be a non-null array of length 2.', e.getMessage());
        }
    }

    @IsTest
    static void testStepEulerInvalidDtThrowsException() {
        DampedOscillator oscillator = (DampedOscillator) JSON.deserialize(
            JSON.serialize(new Map<String, Object>{'omega0' => 1.0, 'gamma' => 1.0}), 
            DampedOscillator.class
        );
        Double[] state = new List<Double>{1.0, 0.0};

        try {
            Test.startTest();
            oscillator.stepEuler(state, (Double)0.0);
            Test.stopTest();
            Assert.fail('Expected IllegalArgumentException for zero dt');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('"Time step must be positive."', e.getMessage());
        }
    }
}