function [f,g] = objfun_s_sparsenorm(x0,A,I,lambda,K);

[L M] = size(A);
batch_size = size(I,2);
s = reshape(x0,M,batch_size);

EI = A*s;

R = I - EI;

s = reshape(x0, M, batch_size);
s_sub = reshape(x0, K, M/K, batch_size);

if 0
    As = zeros(L, M, batch_size);
    for m = 1:M
        As(:,m,:) = A(:,m) * s(m,:);
    end
    As = reshape(As, L, K, M/K, batch_size);
    Q = sum(As, 2);
else
    Amk = reshape(A, L, K, M/K);

    Q = zeros(L, M/K, batch_size);
    for mk = 1:M/K
        for k = 1:K
            Q(:,mk,:) = Q(:,mk,:) + reshape(Amk(:,k,mk) * squeeze(s_sub(k,mk,:))', L, 1, batch_size);
        end
    end
end


As_mag = sqrt(sum(Q.^2, 1));

f_residual = 0.5 * sum(R(:).^2);
f_sparse = lambda * sum(As_mag(:));

f = f_residual + f_sparse;



if nargout > 1
    df_residual = -A'*R;
    df_sparse = zeros(K, M/K, batch_size);


    A = reshape(A, L, K, M/K);

    P = zeros(K, M/K, batch_size);
    if 0
        for b = 1:batch_size
            for k = 1:K
                P(k,:,b) = sum( squeeze(Q(:,1,:,b)) .* squeeze(A(:,k,:)), 1);
            end
        end
    else
        A_b = shiftdim(A, -1);
        A_b = shiftdim(A_b, 1);
        for k = 1:K
            %P(k,:,:) = sum( squeeze(Q(:,1,:,:)) .* squeeze(A_b(:,k,:,ones(1,batch_size))), 1);
            P(k,:,:) = sum( Q .* squeeze(A_b(:,k,:,ones(1,batch_size))), 1);
        end
    end



    if 0
        for k = 1:K
            df_sparse(k,:,:) = 1 ./ shiftdim(As_mag(1,1,:,:),1) .* P(k,:,:);
        end
    else
        %As_mag = shiftdim(As_mag,1);
        df_sparse = P ./ As_mag(ones(1,K), :, :);
    end


    df = df_residual + lambda * reshape(df_sparse, M, batch_size);

    g = df(:);
end

