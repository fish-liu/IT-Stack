package com.grow;

import org.thymeleaf.util.ArrayUtils;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.Future;
import java.util.concurrent.FutureTask;

/**
 * @author liuxw
 * @date 2020/7/16
 * @since 1.0
 */
public class Test {

    public static void main(String [] args){

        int[] ar = {2,5,143,245,344,368,566,578,432,234,123,23};

        //System.out.println(test1(ar));


        List<Integer> result = new LinkedList();
        List<Integer> result1 = new LinkedList();
        test(1,result1);
        test(31654,result);
        System.out.println(result1);
        System.out.println(result);

        StringBuffer sb1 = new StringBuffer();
        for(Integer i : result1){

            sb1.append(arr[i-1]);
        }

        System.out.println(sb1.toString());

        StringBuffer sb = new StringBuffer();
        for(Integer i : result){

            sb.append(arr[i-1]);
        }

        System.out.println(sb.toString());


    }


    public static Integer test2(int[] arr,int index, int num){

        int middle = arr.length% 2 == 0 ? arr.length% 2 : (arr.length+1) % 2;

        int left = arr[middle -1];

        int right = arr[middle +1];

        int m = arr[middle];

        if(left >= m){

            test2(arr,0,left);
        }

        if(right <= m){
            test2(arr,right, arr.length);
        }

        return 1;
    }

    public static Integer test1(int[] arr){
        Map<Integer,Integer> result = new HashMap<>();
        for (int a : arr){
            if(result.containsKey(a)){
                result.put(a,result.get(a)+1);
            }else {
                result.put(a,1);
            }
        }

        int max = 0;
        int val = 0;
        for (Map.Entry<Integer,Integer> e :result.entrySet()){

            if(e.getKey()> max){
                max = e.getKey();
                val = e.getValue();
            }
        }

        return max;
    }


    // 定义数组
    private static String[] arr = new String[]{"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"};



    public static void test(int num,List<Integer> result){

        if(num > 52) {
            int mod = num % 52 ;

            int divide= num / 52;

            if(divide> 52){
                test(divide,result);
            }else {
                result.add(divide);
            }
            result.add(mod);
        } else {
            result.add(num);
        }

    }

}
