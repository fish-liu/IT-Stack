

<h2>最接近的三数之和（3sum-closest）</h2>

------------------------------------------

#### 题目要求

给定一个包括 n 个整数的数组 nums 和 一个目标值 target。找出 nums 中的三个整数，使得它们的和与 target 最接近。返回这三个数的和。假定每组输入只存在唯一答案。

#### 示例

给定数组 nums = [-1，2，1，-4], 和 target = 1.

与 target 最接近的三个数的和为 2. (-1 + 2 + 1 = 2).

#### 解法

> 数组预处理：排序；
> 
>双指针遍历数组的处理方法；

```java
import java.util.Arrays;

public class _16 {
    
    public static class Solution1 {
    
        public int threeSumClosest(int []nums , int target){
            
            // 对数组进行排序
            Arrays.sort(nums);
            
            
            if(nums.length < 3){
                int sum = 0;
                for(int i :nums){
                    sum += i;
                }
                
                return sum;
            }
            
            int sum = nums[0] + nums[1] +nums[2];
            for (int i = 0; i < nums.length -2; i++){
                int left = i+1;
                int right = nums.length -1;
                
                while(left < right){
                    int thisSum = nums[i] + nums[left] + nums[right];
                    
                    if(Math.abs(target - thisSum) < Math.abs(target - sum)){
                        sum = thisSum;
                        
                        if(sum == target){
                            return sum;
                        }
                    }else if(target > thisSum){
                        left++;
                    }else {
                        right--;
                    }
                    
                }
            }
            return sum;
        }
        
    }
    
}
```






