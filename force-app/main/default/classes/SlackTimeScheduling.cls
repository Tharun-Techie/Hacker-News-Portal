/**
 * SlackTimeScheduling is an algorithm that prioritizes tasks based on their
 * slack time, which is defined as the difference between the task's deadline
 * and the time required to execute it. Tasks with less slack time are prioritized.
 *
 * Use Case: Real-time systems with hard deadlines
 */
public class SlackTimeScheduling {

    // Inner class must be public or global to be used in lists/sorting, 
    // and must implement Comparable for native sorting capabilities.
    public class Task implements Comparable {
        public String name;
        public Integer executionTime;
        public Integer deadline;

        public Task(String name, Integer executionTime, Integer deadline) {
            this.name = name;
            this.executionTime = executionTime;
            this.deadline = deadline;
        }

        public Integer getSlackTime() {
            return this.deadline - this.executionTime;
        }

        // Native Apex sorting method contract
        public Integer compareTo(Object compareTo) {
            Task otherTask = (Task) compareTo;
            
            Integer thisSlack = this.getSlackTime();
            Integer otherSlack = otherTask.getSlackTime();
            
            if (thisSlack == otherSlack) {
                return 0;
            }
            return (thisSlack > otherSlack) ? 1 : -1;
        }
    }

    private final List<Task> tasks;

    public SlackTimeScheduling() {
        // Changed Java ArrayList<> to native Apex List syntax
        this.tasks = new List<Task>();
    }

    /**
     * Adds a task to the scheduler.
     *
     * @param name          the name of the task
     * @param executionTime the time required to execute the task
     * @param deadline      the deadline by which the task must be completed
     */
    public void addTask(String name, Integer executionTime, Integer deadline) {
        this.tasks.add(new Task(name, executionTime, deadline));
    }

    /**
     * Schedules the tasks based on their slack time.
     *
     * @return the order in which the tasks should be executed
     */
    public List<String> scheduleTasks() {
        // Native list sorting utilizing the Comparable implementation
        this.tasks.sort();
        
        List<String> scheduledOrder = new List<String>();
        for (Task t : this.tasks) {
            scheduledOrder.add(t.name);
        }
        return scheduledOrder;
    }
}