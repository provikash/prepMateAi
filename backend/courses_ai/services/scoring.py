import re

class CourseScorer:
    def __init__(self, target_skills):
        self.target_skills = [skill.lower() for skill in target_skills]

    def compute_score(self, item):
        score = 0
        title = item.get("title", "").lower()
        description = item.get("description", "").lower()

        # 1. Keyword Relevance (up to 60 points)
        skills_matched = 0
        for skill in self.target_skills:
            if re.search(r'\b' + re.escape(skill) + r'\b', title):
                skills_matched += 1
                score += 25  # Big boost for title match
            elif re.search(r'\b' + re.escape(skill) + r'\b', description):
                skills_matched += 0.5
                score += 10  # Smaller boost for description match

        # 2. View Count / Popularity (up to 20 points)
        # Note: In a real app we'd fetch statistics, for now we simulate
        # if item.get('view_count', 0) > 1000000: score += 20
        # elif item.get('view_count', 0) > 100000: score += 10

        # 3. Content Type (up to 20 points)
        if item.get("video_count", 0) > 5:
            score += 20  # Playlists with many videos are better for learning
        elif item.get("video_count", 0) > 1:
            score += 10

        # Cap at 100
        return min(max(score, 10), 98)
