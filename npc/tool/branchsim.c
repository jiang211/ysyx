#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

// 预测算法类型
typedef enum {
    ALWAYS_TAKEN,      // 总是跳转
    ALWAYS_NOT_TAKEN,  // 总是不跳转
    BTFN               // Backward Taken, Forward Not-taken
} PredictionAlgorithm;

// 分支指令信息
typedef struct {
    uint32_t pc;        // 指令地址
    uint32_t target_pc; // 目标地址
    uint32_t dnpc;      // 下一条指令地址
    int taken;          // 实际是否跳转
    int predicted;      // 预测是否跳转
    int correct;        // 预测是否正确
} BranchRecord;

// 分支预测模拟器
typedef struct {
    PredictionAlgorithm algorithm;  // 预测算法
    BranchRecord* records;          // 分支记录数组
    uint64_t total_branches;        // 总分支指令数
    uint64_t correct_predictions;   // 正确预测数
} BranchSim;

// 初始化分支预测模拟器
void branchsim_init(BranchSim* sim, PredictionAlgorithm algo) {
    memset(sim, 0, sizeof(BranchSim));
    sim->algorithm = algo;
    sim->records = NULL;
}

// 使用指定算法预测分支
int predict_branch(BranchSim* sim, uint32_t pc, uint32_t target_pc) {
    switch (sim->algorithm) {
        case ALWAYS_TAKEN:
            return 1; // 总是预测跳转
            
        case ALWAYS_NOT_TAKEN:
            return 0; // 总是预测不跳转
            
        case BTFN:
            // BTFN: 向后跳转预测跳转，向前跳转预测不跳转
            return (target_pc < pc) ? 1 : 0;
            
        default:
            return 0; // 默认预测不跳转
    }
}

// 处理分支指令
void process_branch(BranchSim* sim, uint32_t pc, uint32_t target_pc, uint32_t dnpc) {
    // 分配更多内存存储记录
    BranchRecord* new_records = realloc(sim->records, 
                                       (sim->total_branches + 1) * sizeof(BranchRecord));
    if (!new_records) {
        perror("内存分配失败");
        return;
    }
    
    sim->records = new_records;
    BranchRecord* record = &sim->records[sim->total_branches];
    
    // 记录分支信息
    record->pc = pc;
    record->target_pc = target_pc;
    record->dnpc = dnpc;
    
    // 判断实际是否跳转 (dnpc != pc+4 表示跳转)
    record->taken = (dnpc != pc + 4);
    
    // 进行预测
    record->predicted = predict_branch(sim, pc, target_pc);
    record->correct = (record->predicted == record->taken);
    
    // 更新统计信息
    sim->total_branches++;
    if (record->correct) {
        sim->correct_predictions++;
    }
}

// 从btrace文件加载分支记录
void load_btrace(BranchSim* sim, const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        perror("无法打开btrace文件");
        return;
    }
    
    // 获取文件大小
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    // 计算记录数 (每条记录12字节: pc(4) + target_pc(4) + dnpc(4))
    long num_entries = file_size / 12;
    printf("文件大小: %ld 字节, 分支记录数: %ld\n", file_size, num_entries);
    
    uint32_t pc, target_pc, dnpc;
    
    for (long i = 0; i < num_entries; i++) {
        // 读取分支记录
        if (fread(&pc, sizeof(pc), 1, file) != 1) {
            perror("读取PC失败");
            break;
        }
        if (fread(&target_pc, sizeof(target_pc), 1, file) != 1) {
            perror("读取目标地址失败");
            break;
        }
        if (fread(&dnpc, sizeof(dnpc), 1, file) != 1) {
            perror("读取下一条PC失败");
            break;
        }
        
        // 处理分支指令
        process_branch(sim, pc, target_pc, dnpc);
        
        // 每10万条记录显示进度
        // if (i % 100000 == 0 && i > 0) {
        //     printf("已处理 %ld 条分支记录...\n", i);
        // }
    }
    
    fclose(file);
}

// 打印预测结果
void print_results(BranchSim* sim) {
    printf("\n分支预测算法: ");
    switch (sim->algorithm) {
        case ALWAYS_TAKEN: printf("总是跳转\n"); break;
        case ALWAYS_NOT_TAKEN: printf("总是不跳转\n"); break;
        case BTFN: printf("BTFN (向后跳转预测跳转，向前跳转预测不跳转)\n"); break;
    }
    
    printf("分支指令数: %lu\n", sim->total_branches);
    printf("正确预测数: %lu\n", sim->correct_predictions);
    
    if (sim->total_branches > 0) {
        printf("预测准确率: %.2f%%\n", 
               (double)sim->correct_predictions / sim->total_branches * 100);
        
        // 计算性能收益 (假设错误预测代价为2周期)
        double penalty_per_miss = 2.0;
        double total_penalty = (sim->total_branches - sim->correct_predictions) * penalty_per_miss;
        printf("总惩罚周期: %.0f\n", total_penalty);
        printf("平均每分支指令惩罚周期: %.4f\n", total_penalty / sim->total_branches);
    } else {
        printf("未发现分支指令\n");
    }
    
    
}

// 释放分配的内存
void branchsim_free(BranchSim* sim) {
    if (sim->records) {
        free(sim->records);
        sim->records = NULL;
    }
}

// 比较三种算法的性能
void compare_algorithms(const char* filename) {
    printf("比较三种分支预测算法的性能:\n");
    printf("============================\n");
    
    BranchSim sim_always_taken, sim_always_not_taken, sim_btfn;
    
    // 测试总是跳转算法
    branchsim_init(&sim_always_taken, ALWAYS_TAKEN);
    load_btrace(&sim_always_taken, filename);
    print_results(&sim_always_taken);
    branchsim_free(&sim_always_taken);
    
    printf("\n");
    
    // 测试总是不跳转算法
    branchsim_init(&sim_always_not_taken, ALWAYS_NOT_TAKEN);
    load_btrace(&sim_always_not_taken, filename);
    print_results(&sim_always_not_taken);
    branchsim_free(&sim_always_not_taken);
    
    printf("\n");
    
    // 测试BTFN算法
    branchsim_init(&sim_btfn, BTFN);
    load_btrace(&sim_btfn, filename);
    print_results(&sim_btfn);
    branchsim_free(&sim_btfn);
}

int main(int argc, char* argv[]) {
    if (argc != 2 && argc != 3) {
        printf("用法: %s <btrace_file> [algorithm]\n", argv[0]);
        printf("算法选项: always_taken, always_not_taken, btfn, compare\n");
        printf("示例: %s branch.bin always_taken\n", argv[0]);
        printf("示例: %s branch.bin compare  # 比较所有算法\n", argv[0]);
        return 1;
    }
    
    // if (argc == 3 && strcmp(argv[2], "compare") == 0) {
    //     // 比较所有算法
    //     compare_algorithms(argv[1]);
    //     return 0;
    // }
    
    // 解析算法参数
    PredictionAlgorithm algo;
    // if (argc == 2 || strcmp(argv[2], "btfn") == 0) {
    //     algo = BTFN; // 默认算法
    // } else if (strcmp(argv[2], "always_taken") == 0) {
    //     algo = ALWAYS_TAKEN;
    // } else if (strcmp(argv[2], "always_not_taken") == 0) {
    //     algo = ALWAYS_NOT_TAKEN;
    // } else {
    //     printf("未知算法: %s\n", argv[2]);
    //     printf("可用算法: always_taken, always_not_taken, btfn, compare\n");
    //     return 1;
    // }
    algo = ALWAYS_TAKEN;
    BranchSim sim;
    branchsim_init(&sim, algo);
    
    printf("开始处理B类指令跟踪文件: %s\n", argv[1]);
    
    // 处理btrace文件
    load_btrace(&sim, argv[1]);
    
    // 输出结果
    print_results(&sim);
    
    // 释放内存
    branchsim_free(&sim);
    
    return 0;
}