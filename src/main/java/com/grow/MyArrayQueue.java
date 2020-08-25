package com.grow;

/**
 * 队列满足的条件是FIFO先进先出，本例是基于数组完成的Queue
 * @author liuxw
 * @since 1.0
 */
public class MyArrayQueue<T> {


    Object[] data = null;
    // 对头指针
    private int front;
    // 队尾指针
    private int rear;

    // 队列中当前的元素
    private int itemNums;

    private int maxSize;

    public MyArrayQueue(Integer maxSize){
        this.data = new Object[maxSize];

        this.maxSize = maxSize;
        this.front = 0;
        this.rear = -1;
        this.itemNums = 0;
    }

    /**
     * 插入元素
     * 1、一般情况下，插入操作是在队列不满的情况下，才调用。因此在插入前，应该先调用isFull
     * 2、在队列中插入元素，正常情况下是在队尾指针(rear)+1的位置上插入，因为我们编写的是循环队列
     *    因此，当队尾指针指向数组顶端的时候，我们要将队尾指针(rear)重置为-1，此时再加1，就是0，也就是数组顶端
     *
     * @param d
     */
    public void enqueue(T d){

        if(isFull()){
            throw new IllegalStateException("queue is full!");
        }

        needCycle();

        data[++rear] = d;
        itemNums++;

    }

    public void needCycle(){
        if(rear == maxSize -1){
            rear = -1;
        }
    }

    /**
     * 移除元素
     * 正常情况下，在remove之前，应该调用isEmpty，如果为空，则不能输入
     * @return
     */
    public T dequeue(){

        if(isEmpty()){
            throw new IllegalStateException("no elements in the queue");
        }

        T t = (T)data[front];

        // 方便gc
        data[front] = null;

        // 指针前移
        front = front +1;
        if(front == maxSize ){
            front = 0;
        }

        itemNums--;
        return t;
    }

    /**
     * 查看队列首部元素，不移除
     * @return
     */
    public T peekFront(){
        if(isEmpty()){
            throw new IllegalStateException("no elements in the queue");
        }

        return (T)data[front];
    }

    public boolean isEmpty() {
        return itemNums == 0;
    }

    public boolean isFull() {
        return itemNums == maxSize;
    }

    public int size() {
        return itemNums;
    }
    public int getMaxSize() {
        return maxSize;
    }


}
