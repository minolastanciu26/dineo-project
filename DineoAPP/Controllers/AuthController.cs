using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly DineoContext _context;

        public AuthController(DineoContext context)
        {
            _context = context;
        }

        // 1. Metoda pentru Logare
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] User loginData)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == loginData.Email && u.Password == loginData.Password);

            if (user == null)
            {
                return Unauthorized(new { message = "Email sau parolă greșită!" });
            }

            return Ok(new { message = "Login reușit!", userId = user.Id });
        }

        // 2. Metoda pentru Înregistrare
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] User newUser)
        {
            // Verificăm dacă email-ul există deja ca să nu avem dubluri
            var exists = await _context.Users.AnyAsync(u => u.Email == newUser.Email);
            if (exists)
            {
                return BadRequest(new { message = "Acest email este deja utilizat!" });
            }

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cont creat cu succes!", userId = newUser.Id });
        }
    }
}