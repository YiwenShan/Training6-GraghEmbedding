clear;
load('ORL_12_area.mat');
DATA = ORL; clear ORL;
N_class = 40; N_per_class = 10;
% load('Yale_64.mat');
% DATA = fea'; clear fea;
% N_class = 15; N_per_class = 11;
[D,N] = size(DATA);
%%
L = 5;
Ntrain = L*N_class; % 训练样本数
Ntest = N-Ntrain;
trainset = zeros([D, Ntrain]); % 训练集
testset  = zeros([D, Ntest]); % 测试集
gndtrain = zeros([Ntrain,1]);
gndtest  = zeros([Ntest, 1]); % gnd_test(i)=第i个测试样本的类别

lb_d=2; ub_d=Ntrain-1; len_d=ub_d-lb_d+1;

N_rnd = 20; % 重复次数
rand('seed', 6);
acc_rnd_d = zeros([N_rnd, len_d]); % 
for rnd = 1:N_rnd
    %% 生成训练集, 测试集
    train_idx = sort(randperm(N_per_class,L)); % 升序排序
    test_idx = setdiff(1:N_per_class,train_idx); % 集合作差: 全集-train_idx
    i_tr = 0; i_te = 0;
    for j=1:N_class % 40个人
        trainset(:,i_tr+1:i_tr+L) = DATA(:, [(j-1)*N_per_class + train_idx]); % 不能[(j-1)*N_per_class +train_idx]
        gndtrain(i_tr+1:i_tr+L) = gnd([(j-1)*N_per_class + train_idx]);
        i_tr = i_tr+L;
        testset(:,i_te+1:i_te+N_per_class-L) = DATA(:,[(j-1)*N_per_class + test_idx]);
        gndtest(i_te+1:i_te+N_per_class-L) = gnd([(j-1)*N_per_class + test_idx]);
        i_te = i_te+N_per_class-L;
    end
    %% 运行 Fisherfaces, 输出E
    [E] = Fisherfaces(trainset, gndtrain);
    %% 计算分类准确度
    for d=lb_d:ub_d
        Y_train = E(:,1:d)'*trainset;
        Y_test  = E(:,1:d)'*testset;
        acc = 0;
        for j=1:Ntest
            y = Y_test(:,j); % d*1
            dist = sum((repmat(y,[1,Ntrain]) - Y_train).^2, 1);
            Mx_i = 1; Mx = dist(1);
            for t=2:Ntrain
                if dist(t) < Mx
                    Mx = dist(t);
                    Mx_i = t;
                end
            end
            pred = gndtrain(Mx_i); % 最近邻的类别 = j号测试样本的类别
            acc = acc + (pred==gndtest(j));
        end
        acc = acc/Ntest; % 
        acc_rnd_d(rnd, d-lb_d+1) = acc; % 每次随机测试的准确度 <- 所有测试样本
    end
end
Acc_d = sum(acc_rnd_d, 1)'/N_rnd; % N_rnd次的平均值
%% 画图
Color = [217,83,25;
    255,153,200;
    77,190,238;
    162,20,47;
    125,46,143;
    119,172,48;
    218,179,255;
    0,114,189;
    189,167,164;
    235,181,156]./255;
node_shape =['+-';'x-';'<-';'>-';'v-';'^-';'o-';'s-';'p-';'*-'; 'o:';'*:';'s:';'.-';];
figure;
plot(lb_d:ub_d, Acc_d, '+-', 'MarkerFaceColor','w','Linewidth', 1.5, 'Color', [237,177,32]./255); hold on;
xlabel('Dims', 'Fontsize', 16);
ylabel('Recognition rate (%)', 'Fontsize', 16);
hold off;
