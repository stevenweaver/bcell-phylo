PATIENT_IDS = ["28729", "48689", "67029", "77612", "78202", "93954", "99361", "99682", "GJS"]
GENES = ["V1", "V2", "V3", "V4", "V5", "V6"] 

rule all:
  input:
    expand("data/out/{patient_id}/{v_gene}.json", patient_id=PATIENT_IDS, v_gene=GENES)

rule clone_unaligned_fasta:
  input:
    "data/input/{patient_id}_{clone}_clone.json",
    "python/json_to_unaligned_fasta.py"
  output:
    "data/out/{patient_id}/clone_{clone}_unaligned.fasta"
  shell:
    "python python/json_to_unaligned_fasta.py -p {wildcards.patient_id} -c {wildcards.clone} --size 30"

rule gene_unaligned_fasta:
  input:
    #"data/out/{patient_id}/clone_{clone}_unaligned.fasta",  
    "data/out/{patient_id}/clone_1_unaligned.fasta",
    "data/out/{patient_id}/clone_2_unaligned.fasta",
    "data/out/{patient_id}/clone_3_unaligned.fasta",
    "data/out/{patient_id}/clone_4_unaligned.fasta",
    "data/out/{patient_id}/clone_5_unaligned.fasta",
    "data/out/{patient_id}/clone_6_unaligned.fasta",
    "python/clone_to_germ_un_nuc.py"
  output:
    #"data/out/{patient_id}/V{clone}_unaligned.fasta",
    "data/out/{patient_id}/V1_unaligned.fasta",
    "data/out/{patient_id}/V2_unaligned.fasta",
    "data/out/{patient_id}/V3_unaligned.fasta",
    "data/out/{patient_id}/V4_unaligned.fasta",
    "data/out/{patient_id}/V5_unaligned.fasta",
    "data/out/{patient_id}/V6_unaligned.fasta",
  shell:
    "python python/clone_to_germ_un_nuc.py -p {wildcards.patient_id}"

### again, check the wild cards here ####
rule unaligned_to_amino_acids:
  input:
    "data/out/{patient_id}/V{v_gene}_unaligned.fasta",
    "python/full_gene_trans_to_AA.py"
  output:
    "data/out/{patient_id}/V{v_gene}_unaligned_corrected_AA.fasta",
    "data/out/{patient_id}/V{v_gene}_unaligned_corrected_nuc.fasta",
    #"data/out/{patient_id}/{v_gene}_unaligned_corrected_AA.fasta",
    #"data/out/{patient_id}/{v_gene}_unaligned_corrected_nuc.fasta",
  shell:
    "python python/full_gene_trans_to_AA.py -p {wildcards.patient_id} -g {wildcards.v_gene}"

############## testing this out with python inside
######################## probably wont work now 
rule alignments:
  input:
    "data/out/{patient_id}/V{v_gene}_unaligned_corrected_AA.fasta",
    #"data/out/{patient_id}/{rearrangement}_unaligned_corrected_AA.fasta",
  output:
    "data/out/{patient_id}/V{v_gene}_aligned_AA.fasta",
    #"data/out/{patient_id}/{rearrangement}_aligned_AA.fasta",
  shell:
    "mafft --amino {input} > {output}"

rule codon_maker:
  input:
    "data/out/{patient_id}/V{v_gene}_aligned_AA.fasta",
    "data/out/{patient_id}/V{v_gene}_unaligned_corrected_nuc.fasta",
    #"data/out/{patient_id}/{rearrangement}_aligned_AA.fasta",
    #"data/out/{patient_id}/{rearrangement}_unaligned_corrected_nuc.fasta",
    "python/AA_to_codon.py"
  output:
    "data/out/{patient_id}/V{v_gene}_codon.fasta",
  shell:
    "python python/AA_to_codon.py -p {wildcards.patient_id} -g {wildcards.v_gene}"
    
rule profile_alignment:
  input:
    "data/out/{patient_id}/V{v_gene}_codon.fasta",
    "data/input/Germline_nuc_V{v_gene}.fasta"
  output:
    "data/out/{patient_id}/V{v_gene}_profile.fasta"
  shell:
    "mafft --add data/input/Germline_nuc_V{wildcards.v_gene}.fasta --reorder {input[0]} > {output}"
    
rule gap_trimmer:
  input:
    "data/out/{patient_id}/V{v_gene}_codon.fasta",
    "python/gap_trimmer.py"
  output:
    "data/out/{patient_id}/V{v_gene}_ungapped.fasta",
  shell:
    "python python/gap_trimmer.py -p {wildcards.patient_id} -g {wildcards.v_gene}"

rule trees:
  input:
    "data/out/{patient_id}/V{v_gene}_ungapped.fasta"
  output:
    "data/out/{patient_id}/V{v_gene}.new"
  shell:
    "FastTree -nt {input} > {output}"

rule v_gene_json:
  input:
    "data/out/{patient_id}/V{v_gene}_AA.fasta",
    "data/out/{patient_id}/V{v_gene}_profile.fasta",
    "data/out/{patient_id}/V{v_gene}.new",
    "python/json_for_dashboard.py"
  output:
    "data/out/{patient_id}/V{v_gene}.json"
  shell:
    "python python/json_for_dashboard.py -p {wildcards.patient_id} -g {wildcards.v_gene}"
