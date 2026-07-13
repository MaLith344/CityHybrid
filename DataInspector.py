import numpy as np
import matplotlib.pyplot as plt

# Define system parameters
M = 1.0        # Mass (kg)
K = 100.0      # Spring constant (N/m)
zeta = 0.1     # Damping ratio (lightly damped)
F0 = 10.0      # Force amplitude (N)

# Calculate natural frequency
wn = np.sqrt(K / M)

# Generate frequency array (omega)
w = np.linspace(0, 20, 500)

# Calculate frequency response amplitude X(omega)
denominator = np.sqrt((wn**2 - w**2)**2 + 4 * (zeta**2) * (w**2) * (wn**2))
X_w = (F0 / M) / denominator

# Plotting the figure
plt.figure(figsize=(8, 5))
plt.plot(w, X_w, 'b-', linewidth=2)
plt.axvline(wn, color='r', linestyle='--', label=f'Natural Freq ($\omega_n$={wn} rad/s)')
plt.title('Frequency Response of Spring-Mass-Damper System')
plt.xlabel('Forcing Frequency, $\omega$ (rad/s)')
plt.ylabel('Steady-State Amplitude, $X$ (m)')
plt.grid(True)
plt.legend()
plt.show()