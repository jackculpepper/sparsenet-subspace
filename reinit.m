
switch datasource
    case 'images'
        load ../data/IMAGES.mat
        [Nsz,Nsz,K] = size(IMAGES);

        % choose an image for this batch
   
        i = ceil(K*rand);
        I = IMAGES(:,:,i);

        Xtest = zeros( L, Btest );
   
        % extract subimages at random from this image to make data vector X
        for b = 1:B
            r = buff + ceil((Nsz-Lsz-2*buff)*rand);
            c = buff + ceil((Nsz-Lsz-2*buff)*rand);

            Xtest(:,b) = reshape(I(r:r+Lsz-1,c:c+Lsz-1), L, 1);

            Xtest(:,b) = Xtest(:,b) - mean(Xtest(:,b));
            Xtest(:,b) = Xtest(:,b) / std(Xtest(:,b));
        end

        atest0 = zeros(M, Btest);

    case 'movies'
        Nsz = 128;
        T = 64;
        topmargin = 15;
        num_chunks = 56;
        load_interval = 1000;
        data_root = '../data/vid075-whiteframes';

 
    case 'tiny'
        Xtest = load_tiny_images( tiny_idx : tiny_idx + Btest - 1 );
        Xtest = reshape( Xtest, Lsz*Lsz*3, Btest );
        Xtest = double(Xtest);
 
        for b = 1 : Btest
            Xtest(:,b) = Xtest(:,b) - mean(Xtest(:,b));
            Xtest(:,b) = Xtest(:,b) / std(Xtest(:,b));
        end
 
        Stest0 = 0.1*randn(M, Btest);
end


if 0
    A = randn(L,M);
    A = A*diag(1./sqrt(sum(A.^2)));
else
    load state/L=3072_M=3072_20100411T153519/A.mat
end

update = 1;


