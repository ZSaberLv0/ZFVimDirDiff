
import os
import filecmp

while True:
    # commands:
    #
    # input: jobId\tlistDir\tsome_path
    # output: jobId\teach_dir_name, end with a `jobId`
    #
    # input: jobId\tlistFile\tsome_path
    # output: jobId\teach_file_name, end with a `jobId`
    #
    # input: jobId\tdiff\tpathL\tpathR
    # output:
    #     jobId\t0 : no diff
    #     jobId\t1 : has diff
    #     jobId\t2 : error
    cmd = input()
    args = cmd.split("\t")
    if args[1] == 'listDir':
        try:
            for f in os.listdir(args[2]):
                if os.path.isdir(args[2] + '/' + f):
                    print(args[0] + '\t' + f)
        except:
            pass
        print(args[0])
    elif args[1] == 'listFile':
        try:
            for f in os.listdir(args[2]):
                if os.path.isfile(args[2] + '/' + f):
                    print(args[0] + '\t' + f)
        except:
            pass
        print(args[0])
    elif args[1] == 'diff':
        try:
            if filecmp.cmp(args[2], args[3]):
                print(args[0] + '\t0')
            else:
                print(args[0] + '\t1')
        except:
            print(args[0] + '\t2')
    else:
        pass

