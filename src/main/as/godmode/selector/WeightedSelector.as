//
// godmode

package godmode.selector {

import godmode.core.RandomStream;
import godmode.core.StatefulTask;
import godmode.core.Task;
import godmode.core.TaskContainer;
import godmode.util.Randoms;

/**
 * A selector that chooses which task to run at random.
 * Each task has a "weight" associated with it that determines how likely it is to be selected
 * relative to the other tasks in the selector. (If all tasks have the same weight, the selection
 * is entirely random.)
 */
public class WeightedSelector extends StatefulTask
    implements TaskContainer
{
    public function WeightedSelector (name :String, rng :RandomStream,
        children :Vector.<WeightedTask>) {
        
        super(name);
        _rands = new Randoms(rng);
        _children = children;
    }
    
    public function get children () :Vector.<Task> {
        var out :Vector.<Task> = new Vector.<Task>(_children.length, true);
        for each (var child :WeightedTask in _children) {
            out.push(child.task);
        }
        return out;
    }
    
    override protected function reset () :void {
        if (_curChild != null) {
            _curChild.task.deactivate();
            _curChild = null;
        }
    }
    
    override protected function update (dt :Number) :int {
        // Are we already running a task?
        var status :int;
        if (_curChild != null) {
            status = _curChild.task.updateTask(dt);
            
            // The task completed
            if (status != RUNNING) {
                _curChild = null;
            }
            
            // Exit immediately, unless our task failed, in which case we'll try to select
            // another one below
            if (status != FAIL) {
                return status;
            }
        }
        
        var numTriedTasks :int = 0;
        while (numTriedTasks < _children.length) {
            var child :WeightedTask = chooseNextChild();
            numTriedTasks++;
            // skip this task on our next call to chooseNextChild
            child.skip = true;
            
            status = child.task.updateTask(dt);
            if (status == RUNNING) {
                _curChild = child;
            }
            
            // Exit immediately, unless our task failed, in which case we'll try to select
            // another one
            if (status != FAIL) {
                resetSkippedStatus();
                return status;
            }
        }
        
        resetSkippedStatus();
        
        // all of our tasks failed
        return FAIL;
    }
    
    protected function chooseNextChild () :WeightedTask {
        var pick :WeightedTask = null;
        var total :Number = 0;
        for each (var child :WeightedTask in _children) {
            if (!child.skip) {
                total += child.weight;
                if (pick == null || _rands.getNumber(total) < child.weight) {
                    pick = child;
                }
            }
        }
        return pick;
    }
    
    protected function resetSkippedStatus () :void {
        for each (var child :WeightedTask in _children) {
            child.skip = false;
        }
    }
    
    protected var _rands :Randoms;
    protected var _children :Vector.<WeightedTask>;
    protected var _curChild :WeightedTask;
}
}