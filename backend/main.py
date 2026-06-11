"""
Sacred KG — Backend API
FastAPI + Supabase + DeepSeek AI
v2.1 — Токены админа в БД (SHA-256, аудит)
"""

import os
import json
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional, List
from uuid import UUID, uuid4

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from jose import JWTError, jwt
from passlib.context import CryptContext
from supabase import create_client, Client

# ─── Config ───────────────────────────────────────
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")  # service_role key
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
JWT_SECRET = os.getenv("JWT_SECRET", "sacred-kg-secret-change-me")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError("SUPABASE_URL and SUPABASE_KEY must be set")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ─── App ──────────────────────────────────────────
app = FastAPI(title="Sacred KG API", version="2.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Auth Helpers ────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer(auto_error=False)

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 7


def hash_token(token: str) -> str:
    """SHA-256 хеш токена — храним только хеш, не сам токен."""
    return hashlib.sha256(token.encode()).hexdigest()


def create_access_token(user_id: str, role: str = "user") -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    payload = {"sub": user_id, "role": role, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=ALGORITHM)


def verify_admin(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    x_admin_token: Optional[str] = Header(None),
) -> bool:
    """Проверка админ-доступа: JWT с role=admin ИЛИ admin-токен из БД."""
    # 1. Admin token через заголовок x-admin-token → проверка в БД
    if x_admin_token:
        try:
            h = hash_token(x_admin_token)
            result = supabase.table("admin_tokens") \
                .select("id, is_active, expires_at, use_count") \
                .eq("token_hash", h) \
                .eq("is_active", True) \
                .execute()
            if result.data:
                row = result.data[0]
                # Проверка срока
                if row.get("expires_at"):
                    expires = datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00"))
                    if expires < datetime.now(timezone.utc):
                        raise HTTPException(status_code=403, detail="Токен просрочен")
                # Аудит: обновить счётчик и время последнего использования
                supabase.table("admin_tokens").update({
                    "last_used_at": "now()",
                    "use_count": row.get("use_count", 0) + 1,
                }).eq("id", row["id"]).execute()
                return True
        except HTTPException:
            raise
        except Exception:
            pass
        raise HTTPException(status_code=403, detail="Недействительный токен администратора")

    # 2. JWT с role=admin
    if credentials:
        try:
            payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[ALGORITHM])
            if payload.get("role") == "admin":
                return True
        except JWTError:
            pass

    raise HTTPException(status_code=403, detail="Административный доступ запрещён")


def verify_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> str:
    """Проверка JWT-токена пользователя. Возвращает user_id."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Требуется авторизация")
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[ALGORITHM])
        return payload["sub"]
    except JWTError:
        raise HTTPException(status_code=401, detail="Недействительный токен")


# ─── Pydantic Models ─────────────────────────────
class PlaceCreate(BaseModel):
    title_ru: str
    title_kg: Optional[str] = None
    title_en: Optional[str] = None
    description_ru: Optional[str] = None
    description_kg: Optional[str] = None
    description_en: Optional[str] = None
    region: str
    category: str = "sacred"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    image_url: Optional[str] = None
    cultural_notes_ru: Optional[str] = None
    cultural_notes_kg: Optional[str] = None
    cultural_notes_en: Optional[str] = None
    route_guidance_ru: Optional[str] = None
    route_guidance_kg: Optional[str] = None
    route_guidance_en: Optional[str] = None
    is_featured: bool = False
    is_active: bool = True


class PlaceUpdate(BaseModel):
    title_ru: Optional[str] = None
    title_kg: Optional[str] = None
    title_en: Optional[str] = None
    description_ru: Optional[str] = None
    description_kg: Optional[str] = None
    description_en: Optional[str] = None
    region: Optional[str] = None
    category: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    image_url: Optional[str] = None
    cultural_notes_ru: Optional[str] = None
    cultural_notes_kg: Optional[str] = None
    cultural_notes_en: Optional[str] = None
    route_guidance_ru: Optional[str] = None
    route_guidance_kg: Optional[str] = None
    route_guidance_en: Optional[str] = None
    is_featured: Optional[bool] = None
    is_active: Optional[bool] = None


class UserRegister(BaseModel):
    email: str
    password: str
    name: Optional[str] = None


class UserLogin(BaseModel):
    email: str
    password: str


class BookingCreate(BaseModel):
    place_id: str
    visit_date: str
    guests: int = 1
    notes: Optional[str] = None


class ReviewCreate(BaseModel):
    place_id: str
    rating: int = Field(ge=1, le=5)
    comment_ru: Optional[str] = None
    comment_kg: Optional[str] = None
    comment_en: Optional[str] = None


class PostCreate(BaseModel):
    title: str
    content_ru: Optional[str] = None
    content_kg: Optional[str] = None
    content_en: Optional[str] = None
    image_url: Optional[str] = None
    place_id: Optional[str] = None


class AiChatRequest(BaseModel):
    message: str
    place_id: Optional[str] = None
    character_mode: str = "atashka"
    language: str = "ru"


class AiConfigUpdate(BaseModel):
    key: str
    value: str


class AdminTokenCreate(BaseModel):
    label: str
    expires_in_days: Optional[int] = None  # NULL = бессрочный


# ─── Админка: Токены (БЕЗОПАСНОСТЬ В БД) ─────────
@app.get("/admin/verify-token")
async def admin_verify_token(x_admin_token: Optional[str] = Header(None)):
    """Фронтенд проверяет токен перед входом."""
    if not x_admin_token:
        return {"valid": False, "reason": "Токен не предоставлен"}
    try:
        h = hash_token(x_admin_token)
        result = supabase.table("admin_tokens") \
            .select("id, label, is_active, expires_at, last_used_at, use_count") \
            .eq("token_hash", h) \
            .eq("is_active", True) \
            .execute()
        if not result.data:
            return {"valid": False, "reason": "Недействительный токен"}
        row = result.data[0]
        if row.get("expires_at"):
            expires = datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00"))
            if expires < datetime.now(timezone.utc):
                return {"valid": False, "reason": "Токен просрочен"}
        # Аудит
        supabase.table("admin_tokens").update({
            "last_used_at": "now()",
            "use_count": row.get("use_count", 0) + 1,
        }).eq("id", row["id"]).execute()
        return {"valid": True, "label": row.get("label", ""), "use_count": row.get("use_count", 0)}
    except Exception as e:
        return {"valid": False, "reason": str(e)}


@app.post("/admin/tokens")
async def admin_create_token(tok: AdminTokenCreate, _=Depends(verify_admin)):
    """Создать новый admin-токен. Возвращает токен ОДИН РАЗ — сохраните его."""
    raw_token = "skg_" + secrets.token_urlsafe(32)  # Sacred KG префикс
    h = hash_token(raw_token)
    expires = None
    if tok.expires_in_days:
        expires = (datetime.now(timezone.utc) + timedelta(days=tok.expires_in_days)).isoformat()
    supabase.table("admin_tokens").insert({
        "token_hash": h,
        "label": tok.label,
        "created_by": "admin",
        "expires_at": expires,
    }).execute()
    return {
        "token": raw_token,
        "label": tok.label,
        "hash": h[:12] + "...",
        "expires_in_days": tok.expires_in_days,
        "warning": "⚠️ Сохраните токен сейчас — он больше никогда не будет показан!"
    }


@app.get("/admin/tokens")
async def admin_list_tokens(_=Depends(verify_admin)):
    """Список всех токенов (без самих токенов — только метаданные)."""
    result = supabase.table("admin_tokens") \
        .select("id, label, created_by, is_active, expires_at, last_used_at, use_count, created_at") \
        .order("created_at", desc=True) \
        .execute()
    return result.data


@app.put("/admin/tokens/{token_id}/toggle")
async def admin_toggle_token(token_id: str, _=Depends(verify_admin)):
    """Включить/выключить токен."""
    existing = supabase.table("admin_tokens").select("is_active").eq("id", token_id).execute()
    if not existing.data:
        raise HTTPException(status_code=404, detail="Токен не найден")
    new_state = not existing.data[0]["is_active"]
    supabase.table("admin_tokens").update({"is_active": new_state}).eq("id", token_id).execute()
    return {"id": token_id, "is_active": new_state}


@app.delete("/admin/tokens/{token_id}")
async def admin_delete_token(token_id: str, _=Depends(verify_admin)):
    """Полностью удалить токен."""
    supabase.table("admin_tokens").delete().eq("id", token_id).execute()
    return {"deleted": True}


@app.post("/setup")
async def setup_first_token():
    """
    Создать первый админ-токен, если таблица admin_tokens пуста.
    Вызывается один раз при первом деплое.
    """
    existing = supabase.table("admin_tokens").select("id").limit(1).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="Система уже настроена")
    raw_token = "skg_" + secrets.token_urlsafe(32)
    h = hash_token(raw_token)
    supabase.table("admin_tokens").insert({
        "token_hash": h,
        "label": "Первый токен (создан автоматически)",
        "created_by": "system",
    }).execute()
    return {
        "token": raw_token,
        "label": "Первый токен",
        "warning": "⚠️ Сохраните этот токен! Используйте его для входа в админ-панель."
    }


# ─── Админка: Места ──────────────────────────────
@app.get("/admin/places")
async def admin_get_places(_: bool = Depends(verify_admin), region: Optional[str] = None):
    query = supabase.table("places").select("*").order("created_at", desc=True)
    if region:
        query = query.eq("region", region)
    result = query.execute()
    return result.data


@app.post("/admin/places")
async def admin_create_place(place: PlaceCreate, _=Depends(verify_admin)):
    data = place.model_dump(exclude_none=True)
    result = supabase.table("places").insert(data).execute()
    return result.data[0]


@app.put("/admin/places/{place_id}")
async def admin_update_place(place_id: str, place: PlaceUpdate, _=Depends(verify_admin)):
    data = place.model_dump(exclude_none=True)
    data["updated_at"] = "now()"
    result = supabase.table("places").update(data).eq("id", place_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Место не найдено")
    return result.data[0]


@app.delete("/admin/places/{place_id}")
async def admin_delete_place(place_id: str, _=Depends(verify_admin)):
    supabase.table("places").delete().eq("id", place_id).execute()
    return {"deleted": True}


# ─── Админка: Пользователи ───────────────────────
@app.get("/admin/users")
async def admin_get_users(_: bool = Depends(verify_admin)):
    result = supabase.table("users").select("*").order("created_at", desc=True).execute()
    return result.data


@app.put("/admin/users/{user_id}/role")
async def admin_set_role(user_id: str, role: str = Query(...), _=Depends(verify_admin)):
    if role not in ("user", "admin"):
        raise HTTPException(status_code=400, detail="Роль должна быть user или admin")
    result = supabase.table("users").update({"role": role}).eq("id", user_id).execute()
    return result.data[0]


# ─── Админка: Бронирования ───────────────────────
@app.get("/admin/bookings")
async def admin_get_bookings(_: bool = Depends(verify_admin)):
    result = supabase.table("bookings").select("*, places(title_ru), users(name, email)").order("created_at", desc=True).execute()
    return result.data


@app.put("/admin/bookings/{booking_id}/status")
async def admin_set_booking_status(booking_id: str, status: str = Query(...), _=Depends(verify_admin)):
    if status not in ("pending", "confirmed", "cancelled"):
        raise HTTPException(status_code=400, detail="Статус: pending, confirmed, cancelled")
    result = supabase.table("bookings").update({"status": status}).eq("id", booking_id).execute()
    return result.data[0]


# ─── Админка: Модерация ─────────────────────────
@app.get("/admin/posts")
async def admin_get_posts(_: bool = Depends(verify_admin)):
    result = supabase.table("community_posts").select("*, users(name)").order("created_at", desc=True).execute()
    return result.data


@app.put("/admin/posts/{post_id}/approve")
async def admin_approve_post(post_id: str, _=Depends(verify_admin)):
    result = supabase.table("community_posts").update({"is_approved": True}).eq("id", post_id).execute()
    return result.data[0]


@app.get("/admin/reviews")
async def admin_get_reviews(_: bool = Depends(verify_admin)):
    result = supabase.table("reviews").select("*, places(title_ru), users(name)").order("created_at", desc=True).execute()
    return result.data


@app.put("/admin/reviews/{review_id}/approve")
async def admin_approve_review(review_id: str, _=Depends(verify_admin)):
    result = supabase.table("reviews").update({"is_approved": True}).eq("id", review_id).execute()
    return result.data[0]


# ─── Админка: AI конфиг ─────────────────────────
@app.get("/admin/ai-config")
async def admin_get_ai_config(_: bool = Depends(verify_admin)):
    result = supabase.table("ai_config").select("*").execute()
    return result.data


@app.put("/admin/ai-config")
async def admin_update_ai_config(cfg: AiConfigUpdate, _=Depends(verify_admin)):
    result = supabase.table("ai_config").update({"value": cfg.value, "updated_at": "now()"}).eq("key", cfg.key).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Настройка не найдена")
    return result.data[0]


# ─── Публичные эндпоинты ────────────────────────
@app.get("/api/health")
async def health():
    return {"status": "ok", "version": "2.1.0"}


@app.get("/api/places")
async def get_places(region: Optional[str] = None, category: Optional[str] = None, search: Optional[str] = None):
    query = supabase.table("places").select("*").eq("is_active", True).order("created_at", desc=True)
    if region:
        query = query.eq("region", region)
    if category:
        query = query.eq("category", category)
    result = query.execute()
    data = result.data
    if search:
        search_lower = search.lower()
        data = [p for p in data if search_lower in (p.get("title_ru", "") or "").lower()
                or search_lower in (p.get("description_ru", "") or "").lower()]
    return data


@app.get("/api/places/{place_id}")
async def get_place(place_id: str):
    result = supabase.table("places").select("*").eq("id", place_id).eq("is_active", True).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Место не найдено")
    return result.data[0]


# ─── Авторизация ────────────────────────────────
@app.post("/api/auth/register")
async def register(user: UserRegister):
    existing = supabase.table("users").select("id").eq("email", user.email).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="Пользователь уже существует")
    hashed = pwd_context.hash(user.password)
    result = supabase.table("users").insert({
        "email": user.email,
        "password_hash": hashed,
        "name": user.name or user.email.split("@")[0],
        "role": "user",
    }).execute()
    new_user = result.data[0]
    token = create_access_token(new_user["id"], "user")
    return {"token": token, "user": {"id": new_user["id"], "email": new_user["email"], "name": new_user["name"], "role": "user"}}


@app.post("/api/auth/login")
async def login(user: UserLogin):
    result = supabase.table("users").select("*").eq("email", user.email).execute()
    if not result.data or not pwd_context.verify(user.password, result.data[0]["password_hash"]):
        raise HTTPException(status_code=401, detail="Неверный email или пароль")
    u = result.data[0]
    if not u.get("is_active", True):
        raise HTTPException(status_code=403, detail="Аккаунт отключён")
    token = create_access_token(u["id"], u.get("role", "user"))
    return {"token": token, "user": {"id": u["id"], "email": u["email"], "name": u["name"], "role": u.get("role", "user")}}


# ─── Избранное ──────────────────────────────────
@app.post("/api/favorites/{place_id}")
async def add_favorite(place_id: str, user_id: str = Depends(verify_user)):
    try:
        supabase.table("favorites").insert({"user_id": user_id, "place_id": place_id}).execute()
        return {"added": True}
    except Exception:
        raise HTTPException(status_code=400, detail="Уже в избранном")


@app.delete("/api/favorites/{place_id}")
async def remove_favorite(place_id: str, user_id: str = Depends(verify_user)):
    supabase.table("favorites").delete().eq("user_id", user_id).eq("place_id", place_id).execute()
    return {"removed": True}


@app.get("/api/favorites")
async def get_favorites(user_id: str = Depends(verify_user)):
    result = supabase.table("favorites").select("*, places(*)").eq("user_id", user_id).execute()
    return result.data


# ─── Бронирования ───────────────────────────────
@app.post("/api/bookings")
async def create_booking(booking: BookingCreate, user_id: str = Depends(verify_user)):
    result = supabase.table("bookings").insert({
        "user_id": user_id,
        "place_id": booking.place_id,
        "visit_date": booking.visit_date,
        "guests": booking.guests,
        "notes": booking.notes,
    }).execute()
    return result.data[0]


@app.get("/api/bookings")
async def get_my_bookings(user_id: str = Depends(verify_user)):
    result = supabase.table("bookings").select("*, places(title_ru, image_url)").eq("user_id", user_id).order("created_at", desc=True).execute()
    return result.data


# ─── Отзывы ─────────────────────────────────────
@app.post("/api/reviews")
async def create_review(review: ReviewCreate, user_id: str = Depends(verify_user)):
    result = supabase.table("reviews").insert({
        "user_id": user_id,
        "place_id": review.place_id,
        "rating": review.rating,
        "comment_ru": review.comment_ru,
        "comment_kg": review.comment_kg,
        "comment_en": review.comment_en,
    }).execute()
    return result.data[0]


@app.get("/api/reviews/{place_id}")
async def get_reviews(place_id: str):
    result = supabase.table("reviews").select("*, users(name, avatar_url)").eq("place_id", place_id).eq("is_approved", True).order("created_at", desc=True).execute()
    return result.data


# ─── Посты сообщества ───────────────────────────
@app.post("/api/posts")
async def create_post(post: PostCreate, user_id: str = Depends(verify_user)):
    result = supabase.table("community_posts").insert({
        "user_id": user_id,
        "title": post.title,
        "content_ru": post.content_ru,
        "content_kg": post.content_kg,
        "content_en": post.content_en,
        "image_url": post.image_url,
        "place_id": post.place_id,
    }).execute()
    return result.data[0]


@app.get("/api/posts")
async def get_posts():
    result = supabase.table("community_posts").select("*, users(name, avatar_url)").eq("is_approved", True).order("created_at", desc=True).execute()
    return result.data


# ─── AI-Гид (DeepSeek) ──────────────────────────
@app.post("/api/ai/chat")
async def ai_chat(req: AiChatRequest, user_id: Optional[str] = Depends(verify_user)):
    if not DEEPSEEK_API_KEY:
        raise HTTPException(status_code=500, detail="DeepSeek API ключ не настроен на сервере")

    prompt_key = "atashka_prompt" if req.character_mode == "atashka" else "apashka_prompt"
    config_result = supabase.table("ai_config").select("value").eq("key", prompt_key).execute()
    system_prompt = config_result.data[0]["value"] if config_result.data else "Ты гид по сакральным местам Кыргызстана."

    place_context = ""
    if req.place_id:
        place_result = supabase.table("places").select("title_ru, description_ru, cultural_notes_ru, region").eq("id", req.place_id).execute()
        if place_result.data:
            p = place_result.data[0]
            place_context = f"\nМесто: {p['title_ru']}\nОписание: {p.get('description_ru', '')}\nКультурные заметки: {p.get('cultural_notes_ru', '')}\nРегион: {p['region']}"

    lang_instruction = {"ru": "Отвечай на русском языке.", "kg": "Отвечай на кыргызском языке.", "en": "Отвечай на английском языке."}.get(req.language, "Отвечай на русском языке.")

    messages = [
        {"role": "system", "content": f"{system_prompt}\n{lang_instruction}\nТы эксперт по сакральным местам Кыргызстана. Отвечай информативно, культурно, с уважением к традициям.{place_context}"},
        {"role": "user", "content": req.message},
    ]

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            "https://api.deepseek.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {DEEPSEEK_API_KEY}", "Content-Type": "application/json"},
            json={"model": "deepseek-chat", "messages": messages, "temperature": 0.7, "max_tokens": 800},
        )
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"DeepSeek API ошибка: {response.text}")

        ai_response = response.json()["choices"][0]["message"]["content"]

    try:
        supabase.table("ai_chats").insert({
            "user_id": user_id,
            "place_id": req.place_id,
            "character_mode": req.character_mode,
            "message": req.message,
            "response": ai_response,
        }).execute()
    except Exception:
        pass

    return {"response": ai_response, "character_mode": req.character_mode}


# ─── Главная ────────────────────────────────────
@app.get("/")
async def root():
    return {"app": "Sacred KG API", "version": "2.1.0", "docs": "/docs"}
