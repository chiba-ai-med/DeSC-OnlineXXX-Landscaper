## receipt_drug.csv (92 GB) と m_drug_who_atc.csv を join し、
## person ごとに「観察期間中に該当 ATC group の薬剤を 1 度でも処方された」flag を作る。
##
## 対象 ATC (3 文字 prefix で揃える):
##   M01 = Anti-inflammatory and antirheumatic products (NSAIDs; H5)
##   H02 = Corticosteroids for systemic use (H5)
##   R06 = Antihistamines for systemic use (H5)
##   A10 = Drugs used in diabetes (H1)
##   C10 = Lipid modifying agents (statins etc; H1)
##   M05 = Drugs for treatment of bone diseases (bisphosphonates; H2)

using Printf

function load_atc_map(path::String)
    drug_atc = Dict{Int, String}()
    open(path) do io
        readline(io)  # header
        for line in eachline(io)
            parts = split(line, ',')
            length(parts) >= 2 || continue
            drug_code_str = strip(parts[1])
            atc           = strip(parts[2])
            isempty(drug_code_str) && continue
            isempty(atc) && continue
            try
                dc = parse(Int, drug_code_str)
                # 3 文字 prefix (例: M01AB12 -> M01)
                if length(atc) >= 3
                    drug_atc[dc] = String(atc[1:3])
                end
            catch
            end
        end
    end
    return drug_atc
end

const TARGET_ATCS = Set(String["M01", "H02", "R06", "A10", "C10", "M05"])

function scan_receipt!(path::String, drug_atc::Dict{Int, String},
                       person_atc::Dict{Int, UInt8})
    # bit flag: M01A=1, H02=2, R06=4, A10B=8, C10A=16, M05B=32
    bit_for = Dict("M01" => UInt8(1), "H02" => UInt8(2), "R06" => UInt8(4),
                    "A10" => UInt8(8), "C10" => UInt8(16), "M05" => UInt8(32))
    open(path) do io
        readline(io)  # header
        line_no = 0
        for line in eachline(io)
            line_no += 1
            parts = split(line, ',')
            length(parts) >= 6 || continue
            kojin_id_str  = parts[4]
            drug_code_str = parts[6]
            isempty(kojin_id_str)  && continue
            isempty(drug_code_str) && continue
            kid = tryparse(Int, kojin_id_str)
            dc  = tryparse(Int, drug_code_str)
            (kid === nothing || dc === nothing) && continue
            atc = get(drug_atc, dc, nothing)
            atc === nothing && continue
            atc in TARGET_ATCS || continue
            person_atc[kid] = get(person_atc, kid, UInt8(0)) | bit_for[atc]
            if line_no % 100_000_000 == 0
                @printf("  line %d, |persons| = %d\n", line_no, length(person_atc))
                flush(stdout)
            end
        end
        @printf("  total lines = %d, |persons with target ATC| = %d\n",
                line_no, length(person_atc))
    end
end

function write_output(outfile::String, person_atc::Dict{Int, UInt8})
    open(outfile, "w") do out
        println(out, "kojin_id\tatc_NSAIDs\tatc_Steroid\tatc_Antihistamine\t" *
                     "atc_Diabetes\tatc_Statin\tatc_Osteoporosis")
        ks = sort!(collect(keys(person_atc)))
        for k in ks
            bf = person_atc[k]
            println(out, "$k\t",
                    ((bf & UInt8(1))  != 0) ? 1 : 0, "\t",
                    ((bf & UInt8(2))  != 0) ? 1 : 0, "\t",
                    ((bf & UInt8(4))  != 0) ? 1 : 0, "\t",
                    ((bf & UInt8(8))  != 0) ? 1 : 0, "\t",
                    ((bf & UInt8(16)) != 0) ? 1 : 0, "\t",
                    ((bf & UInt8(32)) != 0) ? 1 : 0)
        end
    end
end

function main()
    receipt_drug_path = ARGS[1]
    atc_path          = ARGS[2]
    outfile           = ARGS[3]

    println("Loading ATC map ..."); flush(stdout)
    drug_atc = load_atc_map(atc_path)
    println("  drug_atc entries: ", length(drug_atc)); flush(stdout)

    println("\nScanning $receipt_drug_path ..."); flush(stdout)
    person_atc = Dict{Int, UInt8}()
    scan_receipt!(receipt_drug_path, drug_atc, person_atc)

    println("\nWriting $outfile ..."); flush(stdout)
    write_output(outfile, person_atc)
    println("done")
end

main()
