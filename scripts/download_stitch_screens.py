import subprocess
import os
import sys

screens = [
    {
        "index": 1,
        "id": "dd5a73dfe5f9485c97792254abcc52ef",
        "title": "Screen 1: Optimize Resume",
        "slug": "screen_1_optimize_resume",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1VwmEGjsR7KDqmjWe_3pO_52lJTY5ffBRjBqgAxZrSkji3Ci-ze7X4EPZaQTl2XBjdpS0eCTCAHEVWPXnAdkoeQ_Tohd5ZYmbbFmsyvxOn5Gm0LClqxiPceSXrT8Cg5b7uKur9Ep7BZNkQb5Bs_cpyBOQ_VOOhZHwMTbIKaNNdYqTvY5_Ha0fhZQkyGASCpzNOk0X4JCMYBhELbgiOny7xYwgnl9X7VD3HhGYRkpiVS_qxa0b52nLUng9rN",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NmMyYWI3NDcwN2ZlZTFiYThkMzE2M2Q0EgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 1914
    },
    {
        "index": 2,
        "id": "2d3660d52692416ba53cc216c5135b04",
        "title": "Screen 2: Job Match Analysis",
        "slug": "screen_2_job_match_analysis",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1VVqoqkf2eQ6pQ0XJOAKuxD3BAMCYU0GuCPzsbgxHuS5LCmn_QFGDRIPjW4WWTd0k0WkBADRv6PvRvlcnjPQKXENMEeedLsV_h-VHWMIb_al9AJh2aOM4JOIt2W8j0cR-JYFzt_onDwy6CaXSyZqgsubLup-sBt6Fu5iOXqcqL3kzLr_hhHvd9GcEcSAvv624vCuUfpWmI21eIT6yhfu8DmCUS4FIInVnqkEao5HC6zR3BuBj53Y6tAw4MU",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NmRjYmY4NDAwMWE2MzJmMTFiMDRkZjYyEgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 3100
    },
    {
        "index": 3,
        "id": "74f182e0662b410695a0f9c44b4eb611",
        "title": "Screen 3: AI Suggestions",
        "slug": "screen_3_ai_suggestions",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1UiGAd-4XFGbpWBktIa2VFxdCxh0W2Z3uMQbIPeax5nx0rKYHlSSKQ9W2EnlhwFYyLLd4KRoZlyNExNxnaRp3IBUPYBKoOH30o6JHSMIhs9KH9L53LiJTiEVwLs7LYIsDlPujQvhaGDDnQ7NwGOuoJ2T6geGfeCgPE8DYkNNCuLpDcJJb0nCiBh5pF7M4xdvKKKinNb92wuq-fLY23ZDmrcTmFStLDD3wamUEDtjPcGp-m0ThllLmRTt5-s",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NmZkNWFiMTMwMmQzYzI5MjIxMjBlZDMzEgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 3652
    },
    {
        "index": 4,
        "id": "1fabc709b66f4d6faf322c7e1a5b84ea",
        "title": "Screen 4: Suggestion Editor",
        "slug": "screen_4_suggestion_editor",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1Vy7hrajSROxzfBtcS6HA9qGxPOy37GIM41y_nJ-xoAN7ymLGsLQQtQFqAKTKcB_vtqgxiDSDhor7hkLnlgHZ6oOfRb1O2f0LpG89a3qeFh0hfW8zLr0jPBuTxaHnuvAhuYsJIvNOEFO1F6fLF12w6LIIKcplIqPhbjKGSO72wWEp3fSwkVh89x4cv3CWUBuulC7_WbfgBbIVZ1yH4B2FuPB6Ntmgp1rajM6iY2cXDz85AtKLY2cNCqZgL4",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NzE0NmM4NDEwN2M0ZDkxMTRlMWVlNGY1EgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 2248
    },
    {
        "index": 5,
        "id": "abfcb1a4324d4edd9e39fd51dc85e77e",
        "title": "Screen 5: Optimization Summary",
        "slug": "screen_5_optimization_summary",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1UVsnvhZvTCJAOiK0Ljr47QxUYuD-9ZWMuhBIviS_5HAWcSkUr8ZXgKh-o4b-N2zbhzpVgw1hAN3ILbKhbVDil5z5F0RheHvKsTN25gcIOAVJK3XhLjWZOd52HilcD8Pj4mPH2I7llDxcpoJqj716uO6cD0fwGVozGLPiUAouL_Dg7fwuI6jNDJQ6WU2HJKEhEFnXgpbFe60zJGx3f6hX4CNUFluT_-rVpanAYahLFxRdMjIS2lVeYQ7A9e",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NzI5NjZiNzQwMjJkNGRmMWI0Mjk3NTA5EgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 3120
    },
    {
        "index": 6,
        "id": "a78b0be2836b4ce58b22942946945b3a",
        "title": "Screen 6: ATS Analysis",
        "slug": "screen_6_ats_analysis",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1XjfYVaB-213HGp5ATwHqVUSh-3DOs2Hk11pbWWi6SOtHJAxq8NYOb7AOnYz_fca8KeZvVK5hlot6UWgpb5ccWTnbl2hlvtYtWtGy1eHGs-i8wqu7UfwbPPmIUimt6EyDwnHISn-20XvGEHymbEwNT-JgGsw0HQNpRhAp_af5BX-AAk8lZ1axGEyNN-Ridk8NWrdO9wxGJvV3Q3qzSF0s3fFTI1YC4HJu2pw_TxPj_TcLlz0iGnObgBe1Hp",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NzQ3ZDI2NTAwMzM4NGMxN2IwMzM4YjcxEgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 2908
    },
    {
        "index": 7,
        "id": "e22c57de3d8d471983c302d7467ad573",
        "title": "Screen 7: Optimized Resume Preview",
        "slug": "screen_7_optimized_resume_preview",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1WIvlYWjY0814KSdjPCwG3FjPMJMNFieiK3j7T3mRuYAhkyWdM88D3yD97UpmM9GQe6UhUmk-ZVJCa19ccIJtWfzbnnZLQP1prT3khIzd8xqTXPyPrzTrlIF42BDw04S1U6DNN2hizX-KnYH6TQWmxIsi_3MUmMu1uSvfbpvyiHB6Uzs0sht6GzAGjFnN2IL4rQJYoWliCBUNBbsARuvJ4AcKa8-JGEummqL5fnBFthnaTAEYJeso_ShNc",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM2NzY3OTI0NjQwNTIyYTlmMTYxMmU4YjlhEgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 2464
    },
    {
        "index": 8,
        "id": "d96e95e080a3466aa7ea640b033a19c4",
        "title": "Screen 1: AI Credits & Usage (Optimized)",
        "slug": "screen_8_ai_credits_usage",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1WnUwO2YVpO0t8Ssyx1ZU21nWzOiVVTqqMJ2anDmI8Lk6eTof-dzFYw2drGbPwjhx7HQ3Y-Hm1syfFCTyW0V4-bu-vRpTc8Tgnlbi3juIC8gKR1MoYp2UCP3qrs2I9V5jqYJ3AIiUqxJ2z69_66uZvsVcoydDjyg0ZUO_wq-CwGXMl6ADoixHSNI5njVREpn8I--T6kbGVWhl2TcmP4P8TPjda0CuqtBT4rWt_DJb_LFZqvhgsQ9Clqinw",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM3ZmY5ZmE3YjQwNTRjYzcxMmFiMjRhMmM2EgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 2378
    },
    {
        "index": 9,
        "id": "d02bf2c8eae84df2aa5cae85e31f475b",
        "title": "Screen 2: AI Plans & Upgrade (Optimized)",
        "slug": "screen_9_ai_plans_upgrade",
        "image_url": "https://lh3.googleusercontent.com/aida/AEtjO1Vl2Ae4F6qk_F14ScdsM6NbAiOawnTLS4MykinBRJ2Pye42HSBxgDl_32lVWLQriIazJZykz8Lp3YQHuXUv5W42hTPv0S6s2FF_JqBlTPPYZTOGjEAqhs6gXiW9jq7rOy7i1f_2SFvLvPzTpFRBKO-lWlqrBk-otJkfssK9laJUbSY9H5XTi8p0llYUQ89b6AStSAV0ftey1vBeU1nbGmJBTG4H675naxxFprUaTYVBtnWTlR-xbvJ6oScU",
        "html_url": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1YmM3ZmZjYWZkYjIwNTIyYTlmMTYxMmU4YjlhEgsSBxDllLb50RYYAZIBJAoKcHJvamVjdF9pZBIWQhQxNDQ5NTYwNDIxNzQ2MTAxMzg3MQ&filename=&opi=89354086",
        "width": 780,
        "height": 2494
    }
]

base_dir = os.path.abspath("stitch/resume_optimizer")
images_dir = os.path.join(base_dir, "images")
code_dir = os.path.join(base_dir, "code")

os.makedirs(images_dir, exist_ok=True)
os.makedirs(code_dir, exist_ok=True)

print("Starting download of Stitch screens...")

force = "--force" in sys.argv

for s in screens:
    img_dest = os.path.join(images_dir, f"{s['slug']}.png")
    html_dest = os.path.join(code_dir, f"{s['slug']}.html")
    
    print(f"\n--- Downloading {s['title']} ---")
    
    # Download image using curl.exe -L
    if not force and os.path.exists(img_dest) and os.path.getsize(img_dest) > 0:
        print(f"Image already exists -> {os.path.basename(img_dest)} ({os.path.getsize(img_dest):,} bytes)")
    else:
        cmd_img = ["curl.exe", "-L", "-s", "-o", img_dest, s["image_url"]]
        print(f"Downloading image -> {os.path.basename(img_dest)}")
        res_img = subprocess.run(cmd_img)
        if res_img.returncode != 0 or not os.path.exists(img_dest) or os.path.getsize(img_dest) == 0:
            print(f"Failed to download image for {s['title']}")
        else:
            print(f"  Success: {os.path.getsize(img_dest):,} bytes")

    # Download html using curl.exe -L
    if not force and os.path.exists(html_dest) and os.path.getsize(html_dest) > 0:
        print(f"Code already exists -> {os.path.basename(html_dest)} ({os.path.getsize(html_dest):,} bytes)")
    else:
        cmd_html = ["curl.exe", "-L", "-s", "-o", html_dest, s["html_url"]]
        print(f"Downloading code -> {os.path.basename(html_dest)}")
        res_html = subprocess.run(cmd_html)
        if res_html.returncode != 0 or not os.path.exists(html_dest) or os.path.getsize(html_dest) == 0:
            print(f"Failed to download HTML for {s['title']}")
        else:
            print(f"  Success: {os.path.getsize(html_dest):,} bytes")

print("\nAll downloads completed successfully!")
