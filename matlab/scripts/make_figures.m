%% MAKE_FIGURES  Manuscript figures from results/*.csv (PDF vector + 300 dpi JPG).
clear; clc; close all;
here = fileparts(mfilename('fullpath'));
res = fullfile(here, '..', '..', 'results');
fig = fullfile(here, '..', '..', 'figures');
if ~exist(fig, 'dir'), mkdir(fig); end

set(groot, 'defaultAxesFontName', 'Helvetica', 'defaultAxesFontSize', 10, 'defaultAxesTitleFontSizeMultiplier', 0.95, ...
    'defaultAxesBox', 'off', 'defaultLineLineWidth', 1.6, 'defaultAxesTickDir', 'out');
c = struct('blue', [0.12 0.36 0.62], 'orange', [0.85 0.45 0.10], 'green', [0.20 0.55 0.35], ...
           'red', [0.75 0.20 0.20], 'gray', [0.45 0.45 0.45], 'purple', [0.45 0.30 0.60]);
ci = @(x) 1.96 * std(x) / sqrt(numel(x));
save_fig = @(f, name) cellfun(@(e) exportgraphics(f, fullfile(fig, [name e]), 'Resolution', 300), {'.pdf', '.jpg'});

%% Fig 1 - Discovery (E1)
T = readtable(fullfile(res, 'E1_discovery.csv'));
L = unique(T.learnFrac);
f = figure('Position', [100 100 900 340]);
vars = {'GamingPrevalence', 'OverrunPct', 'HHI'};
ttl = {'Winners with inflated signal', 'Cost overrun (%)', 'HHI'};
for k = 1:3
    subplot(1, 3, k); hold on;
    m = arrayfun(@(l) mean(T.(vars{k})(T.learnFrac == l)), L);
    e = arrayfun(@(l) ci(T.(vars{k})(T.learnFrac == l)), L);
    errorbar(100 * L, m, e, '-o', 'Color', c.blue, 'MarkerFaceColor', c.blue, 'CapSize', 4);
    xlabel('Learning suppliers (%)'); title(ttl{k}, 'FontWeight', 'normal');
    if k == 2, yline(19.24, '--', 'Status Quo (base study)', 'Color', c.red, 'LabelHorizontalAlignment', 'left'); ylim([10 21]); end
    if k == 3, yline(1000, '--', 'HHI = 1,000', 'Color', c.red, 'LabelHorizontalAlignment', 'left'); ylim([0 1100]); end
    if k == 1, ylim([0 1]); end
end
save_fig(f, 'fig1_discovery');

%% Fig 2 - Audit and displacement (E6)
A = readtable(fullfile(res, 'E1b_E6_audit_diagnostics.csv'));
A.variant = string(A.variant);
f = figure('Position', [100 100 900 340]);
vars = {'GamingPrevalence', 'OverpriceOnlyValueSharePct', 'OverrunPct'};
ttl = {'Winners with inflated signal', 'Value won with pure overpricing (%)', 'Cost overrun (%)'};
rho = unique(A.rho);
for k = 1:3
    subplot(1, 3, k); hold on;
    for v = ["base" "greedy"]
        col = c.blue; if v == "greedy", col = c.orange; end
        m = arrayfun(@(r) mean(A.(vars{k})(A.variant == v & A.rho == r)), rho);
        e = arrayfun(@(r) ci(A.(vars{k})(A.variant == v & A.rho == r)), rho);
        errorbar(rho, m, e, '-o', 'Color', col, 'MarkerFaceColor', col, 'CapSize', 4, 'DisplayName', char(v));
    end
    xlabel('Verification rate \rho'); title(ttl{k}, 'FontWeight', 'normal');
    if k == 1, legend('Location', 'northeast', 'Box', 'off'); end
end
save_fig(f, 'fig2_audit_displacement');

%% Fig 3 - Blacklist control (E6b)
B = readtable(fullfile(res, 'E6b_blacklist_control.csv'));
f = figure('Position', [100 100 600 340]);
subplot(1, 2, 1); hold on;
for b = [50 0]
    col = c.blue; if b == 0, col = c.green; end
    m = arrayfun(@(r) mean(B.OverpriceOnlyValueSharePct(B.blacklist == b & B.rho == r)), [0 0.2 0.5]);
    e = arrayfun(@(r) ci(B.OverpriceOnlyValueSharePct(B.blacklist == b & B.rho == r)), [0 0.2 0.5]);
    errorbar([0 0.2 0.5], m, e, '-o', 'Color', col, 'MarkerFaceColor', col, 'CapSize', 4, 'DisplayName', sprintf('blacklist = %d', b));
end
xlabel('\rho'); title('Pure-overpricing value share (%)', 'FontWeight', 'normal'); legend('Box', 'off', 'Location', 'northwest');
subplot(1, 2, 2); hold on;
for b = [50 0]
    col = c.blue; if b == 0, col = c.green; end
    m = arrayfun(@(r) mean(B.OverrunPct(B.blacklist == b & B.rho == r)), [0 0.2 0.5]);
    e = arrayfun(@(r) ci(B.OverrunPct(B.blacklist == b & B.rho == r)), [0 0.2 0.5]);
    errorbar([0 0.2 0.5], m, e, '-o', 'Color', col, 'MarkerFaceColor', col, 'CapSize', 4);
end
xlabel('\rho'); title('Cost overrun (%)', 'FontWeight', 'normal'); ylim([13 17]);
save_fig(f, 'fig3_blacklist_control');

%% Fig 4 - Ring (E3b)
R = readtable(fullfile(res, 'E3b_ring_aware.csv'));
sizes = [0 10 20 40 60 80];
f = figure('Position', [100 100 600 340]);
subplot(1, 2, 1); hold on;
base = R.OverrunPct(R.ringSize == 0);
for lam = [0 1]
    col = c.gray; if lam == 1, col = c.red; end
    m = [mean(base) arrayfun(@(n) mean(R.OverrunPct(R.ringSize == n & R.lambda == lam & R.aware == 0)), sizes(2:end))];
    e = [ci(base) arrayfun(@(n) ci(R.OverrunPct(R.ringSize == n & R.lambda == lam & R.aware == 0)), sizes(2:end))];
    errorbar(sizes, m, e, '-o', 'Color', col, 'MarkerFaceColor', col, 'CapSize', 4, 'DisplayName', sprintf('\\lambda = %d', lam));
end
xlabel('Ring size n'); title('Cost overrun (%)', 'FontWeight', 'normal'); legend('Box', 'off', 'Location', 'northwest');
subplot(1, 2, 2); hold on;
m = [mean(R.HHI(R.ringSize == 0)) arrayfun(@(n) mean(R.HHI(R.ringSize == n & R.lambda == 1 & R.aware == 0)), sizes(2:end))];
e = [ci(R.HHI(R.ringSize == 0)) arrayfun(@(n) ci(R.HHI(R.ringSize == n & R.lambda == 1 & R.aware == 0)), sizes(2:end))];
errorbar(sizes, m, e, '-o', 'Color', c.red, 'MarkerFaceColor', c.red, 'CapSize', 4);
yline(1000, '--', 'HHI = 1,000', 'Color', c.red, 'LabelHorizontalAlignment', 'left'); ylim([0 1100]);
xlabel('Ring size n'); title('HHI (\lambda = 1)', 'FontWeight', 'normal');
save_fig(f, 'fig4_ring');

%% Fig 5 - Poisoning channel (E4b)
P = readtable(fullfile(res, 'E4b_poisoning_control.csv'));
f = figure('Position', [100 100 900 340]);
vars = {'GamingPrevalence', 'TrueQuality', 'OverrunPct'};
ttl = {'Winners with inflated signal', 'Delivered quality of winners', 'Cost overrun (%)'};
for k = 1:3
    subplot(1, 3, k); hold on;
    groups = {[1 0.1], [1 0.3], [2 0.1], [2 0.3]};
    for g = 1:4
        pp = groups{g}(1); w = groups{g}(2);
        for tr = [0 1]
            x = P.(vars{k})(P.pop == pp & P.w3 == w & P.recordTruth == tr);
            col = c.red; if tr == 1, col = c.green; end
            errorbar(g + 0.12 * (tr - 0.5) * 2, mean(x), ci(x), 'o', 'Color', col, 'MarkerFaceColor', col, 'CapSize', 4);
        end
    end
    set(gca, 'XTick', 1:4, 'XTickLabel', {'L, .1', 'L, .3', 'F, .1', 'F, .3'}); xlim([0.4 4.6]);
    xlabel('Group, w_3'); title(ttl{k}, 'FontWeight', 'normal');
    if k == 1
        h1 = plot(nan, nan, 'o', 'Color', c.red, 'MarkerFaceColor', c.red, 'DisplayName', 'poisoned record');
        h2 = plot(nan, nan, 'o', 'Color', c.green, 'MarkerFaceColor', c.green, 'DisplayName', 'truthful record');
        legend([h1 h2], 'Box', 'off', 'Location', 'northeast', 'FontSize', 8);
    end
end
save_fig(f, 'fig5_poisoning_channel');

%% Fig 6 - PRCC (E5)
Q = readtable(fullfile(res, 'E5_prcc.csv'), 'ReadRowNames', true);
M = Q{:, :};
f = figure('Position', [100 100 640 380]);
imagesc(M, [-1 1]); colormap(redbluecmap_local()); cb = colorbar; cb.Label.String = 'PRCC';
set(gca, 'XTick', 1:width(Q), 'XTickLabel', Q.Properties.VariableNames, 'XTickLabelRotation', 30, ...
    'YTick', 1:height(Q), 'YTickLabel', Q.Properties.RowNames, 'TickLabelInterpreter', 'none');
for i = 1:size(M, 1)
    for j = 1:size(M, 2)
        text(j, i, sprintf('%.2f', M(i, j)), 'HorizontalAlignment', 'center', 'FontSize', 8, ...
            'Color', ternary(abs(M(i, j)) > 0.5, 'w', 'k'));
    end
end
save_fig(f, 'fig6_prcc');

%% Fig 7 - Discovery speed (E1c)
S = load(fullfile(res, 'E1c_discovery_speed.mat'));
f = figure('Position', [100 100 800 320]); hold on;
cols = {c.blue, c.green, c.orange};
styles = {'-', '--'};
x = (1:size(S.series, 2)) * S.blk / 1000;
for qi = 1:2
    q0 = [0 -1]; q0 = q0(qi);
    for ai = 1:3
        a = [0.05 0.10 0.30]; a = a(ai);
        s = mean(S.series(S.A2 == a & S.Q2 == q0, :), 1);
        plot(x, s, styles{qi}, 'Color', cols{ai}, 'DisplayName', sprintf('Q_0=%d, \\alpha=%.2f', q0, a));
    end
end
xlabel('Tenders (thousands)'); ylabel('Greedy-inflating learners (share)');
legend('Box', 'off', 'Location', 'eastoutside', 'FontSize', 8);
save_fig(f, 'fig7_discovery_speed');
disp('Figures written to figures/');

function out = ternary(cond, a, b), if cond, out = a; else, out = b; end, end
function cmap = redbluecmap_local()
    n = 64; t = linspace(0, 1, n)';
    cmap = [interp1([0 0.5 1], [0.12 1 0.75], t) interp1([0 0.5 1], [0.36 1 0.20], t) interp1([0 0.5 1], [0.62 1 0.20], t)];
end
