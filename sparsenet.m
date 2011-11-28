

for t = 1:num_trials

    switch datasource
        case 'images'
            % choose an image for this batch

            i = ceil(K*rand);
            I = IMAGES(:,:,i);

            X = zeros(L,B);

            % extract subimages at random from this image to make data vector X
            for b = 1:B
                r = buff + ceil((Nsz-Lsz-2*buff)*rand);
                c = buff + ceil((Nsz-Lsz-2*buff)*rand);

                X(:,b) = reshape(I(r:r+Lsz-1,c:c+Lsz-1), L, 1);

                X(:,b) = X(:,b) - mean(X(:,b));
                X(:,b) = X(:,b) / std(X(:,b));
            end

        case 'movies'

            X = zeros(L,B);
            for b = 1:B
                if (~exist('F','var') || mod(t*B+b,load_interval) == 0)
                    % choose a movie for this batch
                    j = ceil(num_chunks*rand);
                    F = read_chunk(data_root,j,Nsz,T);
                    fprintf('loading chunk %d\n', j);
                end

                f = ceil(T*rand);

                r = topmargin+Lsz/2+buff+ceil((Nsz-Lsz-(topmargin+2*buff))*rand);
                c = Lsz/2+buff+ceil((Nsz-Lsz-2*buff)*rand);
                X(:,b) = reshape(F(r-Lsz/2:r+Lsz/2-1,c-Lsz/2:c+Lsz/2-1,f),L,1);

                X(:,b) = X(:,b) - mean(X(:,b));
                X(:,b) = X(:,b) / std(X(:,b));
            end

        case 'tiny'
            X = zeros(L,B);
            for b = 1 : B
                while std(X(:,b)) == 0
                    Xb = load_tiny_images(tiny_idx);

                    X(:,b) = double(reshape(Xb, L, 1));

                    tiny_idx = tiny_idx + 1;
                    if tiny_idx > tiny_size
                        tiny_idx = 1;
                    end

                    if std(X(:,b)) == 0
                        fprintf('zero variance at tiny_idx %d\n', tiny_idx);
                    end
                    fprintf('\r%d ', tiny_idx);
                end

                X(:,b) = X(:,b) - mean(X(:,b));
                X(:,b) = X(:,b) / std(X(:,b));
            end
    end



    S = 0.1*randn(M, B);

    tic;

    switch mintype_inf
        case 'minFunc_sparsenorm'

            options.Display = 'off'; % full,final,iter
            options.MaxFunEvals = 10;

            obj0 = objfun_s_sparsenorm(S,A,X,lambda,K);

            S = minFunc(@objfun_s_sparsenorm, S(:), options, A, X, lambda, K);
            S = reshape(S, M, B);

            obj1 = objfun_s_sparsenorm(S,A,X,lambda,K);


            EI = A*S;
            snr = 10 * log10 ( sum(X(:).^2) / sum(sum((X-EI).^2)) );



    end

    time_inf = toc;




    % update bases

    switch mintype_lrn
        case 'minFunc_sparsenorm'
            tic;
            options.Display = 'off'; % full,final,iter
            options.MaxFunEvals = 1;

            obj0 = objfun_A_sparsenorm(A(:),S,X,lambda,K);
            A1 = minFunc(@objfun_A_sparsenorm, A(:), options, S, X, lambda, K);
            A1 = reshape(A1, L, M);
            obj1 = objfun_A_sparsenorm(A1(:),S,X,lambda,K);

            time_lrn = toc;

        case 'gd_sparsenorm'
            tic;

            [obj0, g] = objfun_A_sparsenorm(A(:),S,X,lambda,K);
            A1 = A - eta * reshape(g, L, M);

            obj1 = objfun_A_sparsenorm(A1(:),S,X,lambda,K);

            time_lrn = toc;

    end

    %% pursue a constant change in angle
    angle_A = acos(A1(:)' * A(:) / sqrt(sum(A1(:).^2)) / sqrt(sum(A(:).^2)));
    if angle_A < target_angle
        eta = eta*1.01;
    else
        eta = eta*0.99;
    end

    A = A1;

    if (obj1 > obj0)
        fprintf('warning: objective function increased\n');
    end
 
    eta_log = eta_log(1:update-1);
    eta_log = [ eta_log ; eta ];





    if (test_every == 1 || mod(update,test_every)==0)
        %% do inference on the test set

        switch mintype_inf
            case 'minFunc_sparsenorm'
                options.Display = 'off'; % full,final,iter
                options.MaxFunEvals = 10;

                Stest1 = minFunc(@objfun_s_sparsenorm, Stest0(:), options, A, Xtest, lambda, K);
                Stest1 = reshape(Stest1, M, Btest);

        end

        Stest0 = Stest1;

        objtest = objfun_s_sparsenorm(Stest1,A,Xtest,lambda,K);
        objtest_log = [ objtest_log objtest ];

        figure(7);
        plot(1:length(objtest_log), objtest_log, 'r-');
    end





    %% display

    if (display_every == 1 || mod(update,display_every)==0)

        % Display the bfs
        array = render_network_color(A, Mrows, 3);
 
        figure(1); clf; subp(1,1,1); imagesc(array); axis image off;


        figure(5);
        hist(S(:),100);
        axis tight;

        figure(6); colormap(gray); imagesc(S); drawnow;

        figure(8);
        plot(1:update, eta_log, 'r-');


        if (save_every == 1 || mod(update,save_every)==0)
            array_frame = uint8(255*((array+1)/2)+1);

            [sucess,msg,msgid] = mkdir(sprintf('state/%s', paramstr));
 
            imwrite(array, ...
                sprintf('state/%s/bf_up=%06d.png',paramstr,update), ...
                'png');

            eval(sprintf('save state/%s/A.mat A',paramstr));
            eval(sprintf('save state/%s/A_up=%06d.mat A',paramstr,update));

            saveparamscmd = sprintf('save state/%s/params.mat', paramstr);
            saveparamscmd = sprintf('%s lambda', saveparamscmd);
            saveparamscmd = sprintf('%s eta', saveparamscmd);
            saveparamscmd = sprintf('%s tol_inf', saveparamscmd);
            saveparamscmd = sprintf('%s B', saveparamscmd);
            saveparamscmd = sprintf('%s K', saveparamscmd);
            saveparamscmd = sprintf('%s L', saveparamscmd);
            saveparamscmd = sprintf('%s Lsz', saveparamscmd);
            saveparamscmd = sprintf('%s M', saveparamscmd);
            saveparamscmd = sprintf('%s Mrows', saveparamscmd);
            saveparamscmd = sprintf('%s eta_log', saveparamscmd);
            saveparamscmd = sprintf('%s objtest_log', saveparamscmd);
            eval(saveparamscmd);
        end
        drawnow;

    end

    % renormalize
    A = A*diag(1./sqrt(sum(A.^2)));

    fprintf('%s update %d snr %.4f eta %.4f', paramstr, update, snr, eta);
    fprintf(' o0 %.4f o1 %.4f dl %.4f', obj0, obj1, obj0-obj1);
    fprintf(' ang %.4f', angle_A);
    fprintf(' inf %.4f lrn %.4f', time_inf, time_lrn);
    fprintf('\n');

    update = update + 1;
end

