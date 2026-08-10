@IsTest
private class SlackTimeSchedulingTest {

    @IsTest
    static void testScheduleTasksSortingOrder() {
        // Arrange
        SlackTimeScheduling scheduler = new SlackTimeScheduling();
        
        // Task A: Slack = 10 - 2 = 8
        scheduler.addTask('Task A', 2, 10);
        // Task B: Slack = 5 - 4 = 1
        scheduler.addTask('Task B', 4, 5);
        // Task C: Slack = 20 - 15 = 5
        scheduler.addTask('Task C', 15, 20);

        // Act
        Test.startTest();
        List<String> orderedTasks = scheduler.scheduleTasks();
        Test.stopTest();

        // Assert
        // Expected order by lowest slack time: Task B (1), Task C (5), Task A (8)
        Assert.areNotEqual(null, orderedTasks, 'The scheduled list should not be null');
        Assert.areEqual(3, orderedTasks.size(), 'The list should contain exactly 3 items');
        Assert.areEqual('Task B', orderedTasks[0], 'Task B should be prioritized first');
        Assert.areEqual('Task C', orderedTasks[1], 'Task C should be prioritized second');
        Assert.areEqual('Task A', orderedTasks[2], 'Task A should be prioritized last');
    }

    @IsTest
    static void testScheduleTasksWithEqualSlackTime() {
        // Arrange
        SlackTimeScheduling scheduler = new SlackTimeScheduling();
        
        // Both tasks have an identical slack time of 5
        scheduler.addTask('First Added', 5, 10);
        scheduler.addTask('Second Added', 2, 7);

        // Act
        Test.startTest();
        List<String> orderedTasks = scheduler.scheduleTasks();
        Test.stopTest();

        // Assert
        Assert.areEqual(2, orderedTasks.size(), 'The list should contain exactly 2 items');
        // Items with equal slack should maintain relative stability or evaluate to 0 match
        Assert.isTrue(orderedTasks.contains('First Added'), 'Missing First Added task');
        Assert.isTrue(orderedTasks.contains('Second Added'), 'Missing Second Added task');
    }

    @IsTest
    static void testEmptySchedulerReturnsEmptyList() {
        // Arrange
        SlackTimeScheduling scheduler = new SlackTimeScheduling();

        // Act
        Test.startTest();
        List<String> orderedTasks = scheduler.scheduleTasks();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, orderedTasks, 'The list object should still be instantiated');
        Assert.areEqual(0, orderedTasks.size(), 'The list should be completely empty');
    }
}